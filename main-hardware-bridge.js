/**
 * BBK Gym Hardware Bridge - Main Process
 * Electron app that connects hardware devices with cloud dashboard
 */

const { app, BrowserWindow, Menu, ipcMain, screen, Notification } = require('electron');
const path = require('path');
const { spawn, exec } = require('child_process');
const WebSocket = require('ws');
const fs = require('fs');
const log = require('electron-log');
const net = require('net');
const https = require('https');
const http = require('http');

// Cloudflared is optional - only needed for cloud tunnel
let Tunnel;
try {
  const cloudflared = require('cloudflared');
  Tunnel = cloudflared.Tunnel;
} catch (e) {
  log.warn('Cloudflared not installed - tunnel feature disabled');
  Tunnel = null;
}

// Configure logging
log.transports.file.resolvePathFn = () => path.join(__dirname, 'logs', 'electron.log');
log.info('BBK Hardware Bridge starting...');

// Windows
let employeeWindow = null;
let memberWindow = null;

// Python bridge
let pythonProcess = null;
let pythonWs = null;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;

// Cloudflare Tunnel
let cloudflaredProcess = null;
let tunnelUrl = null;

// Configuration
let config = {};

// Event queue for offline mode
const eventQueue = [];

/**
 * Simple fetch wrapper using native http/https
 */
function fetch(url) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    
    protocol.get(url, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        resolve({
          ok: res.statusCode >= 200 && res.statusCode < 300,
          status: res.statusCode,
          statusText: res.statusMessage,
          json: () => Promise.resolve(JSON.parse(data)),
          text: () => Promise.resolve(data)
        });
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

/**
 * Load configuration from config.json
 */
function loadConfig() {
  try {
    const configPath = path.join(__dirname, 'config.json');
    const configData = fs.readFileSync(configPath, 'utf8');
    config = JSON.parse(configData);
    log.info('Configuration loaded successfully');
    return config;
  } catch (error) {
    log.error('Failed to load config.json:', error);
    // Use defaults
    config = {
      screens: {
        employee: {
          url: 'https://bbkdashboard.vercel.app/',
          display_index: 0,
          dev_tools: false
        },
        member: {
          url: 'https://bbkdashboard.vercel.app/member-screen',
          display_index: 1,
          fullscreen: true,
          kiosk_mode: true
        }
      },
      hardware: {
        fingerprint: {
          ip: '192.168.1.201',
          port: 4370,
          timeout: 5
        },
        doorlock: {
          port: 'COM7',
          baudrate: 9600,
          open_duration: 5000
        }
      },
      python_bridge: {
        enabled: true,
        port: 8000,
        auto_start: true,
        executable: path.join(__dirname, 'python-bridge', 'main.py')
      },
      ui: {
        popup_duration: 5000,
        sound_enabled: true
      }
    };
    return config;
  }
}

/**
 * Create Employee Screen (Admin Dashboard)
 */
function createEmployeeWindow() {
  const displays = screen.getAllDisplays();
  const displayIndex = config.screens.employee.display_index || 0;
  const targetDisplay = displays[displayIndex] || displays[0];
  
  employeeWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    x: targetDisplay.bounds.x,
    y: targetDisplay.bounds.y,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'renderer', 'employee-preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    title: 'BBK Gym - Employee Dashboard',
    backgroundColor: '#0f172a'
  });

  employeeWindow.loadURL(config.screens.employee.url);

  if (config.screens.employee.dev_tools) {
    employeeWindow.webContents.openDevTools();
  }

  employeeWindow.on('closed', () => {
    employeeWindow = null;
  });
  
  log.info(`Employee window created on display ${displayIndex}`);
}

/**
 * Create Member Screen (Kiosk Display)
 */
function createMemberWindow() {
  const displays = screen.getAllDisplays();
  const displayIndex = config.screens.member.display_index || 1;
  
  // Check if we have a second display
  if (displays.length < displayIndex + 1) {
    log.warn(`Display ${displayIndex} not found. Member screen will not be created.`);
    return;
  }
  
  const targetDisplay = displays[displayIndex];
  
  memberWindow = new BrowserWindow({
    width: targetDisplay.bounds.width,
    height: targetDisplay.bounds.height,
    x: targetDisplay.bounds.x,
    y: targetDisplay.bounds.y,
    fullscreen: config.screens.member.fullscreen,
    kiosk: config.screens.member.kiosk_mode,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'renderer', 'member-preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    title: 'BBK Gym - Member Kiosk',
    backgroundColor: '#000000',
    autoHideMenuBar: true,
    frame: !config.screens.member.kiosk_mode
  });

  memberWindow.loadURL(config.screens.member.url);

  // Allow Escape to exit kiosk mode
  if (config.screens.member.kiosk_mode) {
    memberWindow.webContents.on('before-input-event', (event, input) => {
      if (input.key === 'Escape' && input.type === 'keyDown') {
        memberWindow.setKiosk(false);
        memberWindow.setFullScreen(false);
        log.info('Kiosk mode exited via Escape key');
      }
    });
  }

  memberWindow.on('closed', () => {
    memberWindow = null;
  });
  
  log.info(`Member window created on display ${displayIndex}`);
}

/**
 * Check if port is available
 */
function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.once('error', () => resolve(false));
    server.once('listening', () => {
      server.close();
      resolve(true);
    });
    server.listen(port, '0.0.0.0');
  });
}

/**
 * Kill any existing BBK-Bridge processes
 */
function killExistingBridge() {
  return new Promise((resolve) => {
    if (process.platform === 'win32') {
      exec('taskkill /F /IM BBK-Bridge.exe', (error) => {
        // Ignore error if process not found
        setTimeout(resolve, 1000); // Wait 1s for cleanup
      });
    } else {
      exec('pkill -9 BBK-Bridge', (error) => {
        setTimeout(resolve, 1000);
      });
    }
  });
}

/**
 * Start Python bridge service
 */
async function startPythonBridge() {
  if (!config.python_bridge.enabled || !config.python_bridge.auto_start) {
    log.info('Python bridge disabled in config');
    return;
  }
  
  try {
    log.info('Starting Python bridge service...');
    
    // Check if port is available
    const port = config.python_bridge.port || 8000;
    const portAvailable = await isPortAvailable(port);
    
    if (!portAvailable) {
      log.warn(`Port ${port} is already in use, killing existing bridge process...`);
      await killExistingBridge();
      
      // Wait and check again
      await new Promise(resolve => setTimeout(resolve, 2000));
      const stillBusy = !(await isPortAvailable(port));
      if (stillBusy) {
        log.error(`Port ${port} still in use after cleanup. Cannot start bridge.`);
        return;
      }
    }
    
    // Build full path to BBK-Bridge.exe
    const exePath = path.join(__dirname, 'python-bridge', config.python_bridge.executable);
    const workingDir = path.join(__dirname, 'python-bridge');
    
    log.info(`Launching bridge: ${exePath}`);
    
    // Spawn executable directly (it's a standalone .exe, not a Python script)
    pythonProcess = spawn(exePath, [], {
      cwd: workingDir,
      env: { ...process.env }
    });
    
    pythonProcess.stdout.on('data', (data) => {
      log.info(`[Python]: ${data.toString().trim()}`);
    });
    
    pythonProcess.stderr.on('data', (data) => {
      log.error(`[Python Error]: ${data.toString().trim()}`);
    });
    
    pythonProcess.on('close', (code) => {
      log.warn(`Python bridge process exited with code ${code}`);
      pythonProcess = null;
      
      // Auto-restart on crash
      if (code !== 0 && reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        reconnectAttempts++;
        log.info(`Attempting to restart Python bridge (attempt ${reconnectAttempts})...`);
        setTimeout(startPythonBridge, 5000);
      }
    });
    
    // Wait for service to start, then connect WebSocket
    setTimeout(async () => {
      await connectToPythonBridge();
      // Start Cloudflare tunnel if using cloud dashboard
      const shouldStartTunnel = config.screens.employee.url.includes('vercel.app') || config.cloudflare?.enabled;
      log.info(`Tunnel check: vercel=${config.screens.employee.url.includes('vercel.app')}, cloudflare.enabled=${config.cloudflare?.enabled}, shouldStart=${shouldStartTunnel}`);
      if (shouldStartTunnel) {
        await startCloudflareTunnel();
      } else {
        log.warn('Cloudflare tunnel disabled - running in local-only mode');
      }
    }, 3000);
    
  } catch (error) {
    log.error('Failed to start Python bridge:', error);
  }
}

/**
 * Start Cloudflare Tunnel to expose local bridge to cloud
 * Uses authenticated tunnel for PERMANENT static URL
 */
async function startCloudflareTunnel() {
  try {
    // Check if cloudflared is available
    if (!Tunnel) {
      log.error('❌ Cloudflare tunnel not available - cloudflared module not installed');
      log.error('To enable tunnel:');
      log.error('1. Run: npm install cloudflared');
      log.error('2. Restart the app');
      return;
    }
    
    log.info('Starting Cloudflare tunnel...');
    
    const port = config.python_bridge.port || 8000;
    const tunnelToken = config.cloudflare?.tunnel_token;
    
    let tunnel;
    
    if (tunnelToken) {
      // Use authenticated tunnel with token (PERMANENT URL)
      log.info('Using authenticated Cloudflare tunnel with token...');
      tunnel = Tunnel.withToken(tunnelToken);
    } else {
      // Use quick tunnel (URL changes on restart - not recommended)
      log.warn('⚠️ No tunnel token configured! URL will change on restart!');
      log.warn('⚠️ To get a permanent URL, add tunnel_token to config.json');
      log.warn('⚠️ Visit: https://dash.cloudflare.com to create a tunnel');
      tunnel = Tunnel.quick(`http://localhost:${port}`);
    }
    
    cloudflaredProcess = tunnel;
    
    // Wait for tunnel URL
    tunnel.once('url', (url) => {
      tunnelUrl = url;
      const isStatic = tunnelToken ? true : false;
      
      log.info(`✅ Cloudflare tunnel established: ${tunnelUrl}`);
      log.info(`🌐 Cloud dashboard can now connect to: ${tunnelUrl.replace('https://', '')}`);
      
      if (isStatic) {
        log.info(`📌 This URL is PERMANENT and never changes!`);
      } else {
        log.warn(`⚠️ This URL is TEMPORARY and will change on restart!`);
        log.warn(`⚠️ Add tunnel_token to config.json for a permanent URL`);
      }
      
      // Show notification
      if (Notification.isSupported()) {
        const title = isStatic 
          ? 'BBK Bridge - Permanent Tunnel Active'
          : 'BBK Bridge - Temporary Tunnel (URL Changes on Restart)';
        
        const body = isStatic
          ? `✅ PERMANENT URL: ${tunnelUrl}\n\nAdd to Vercel:\nNEXT_PUBLIC_BRIDGE_URL=${tunnelUrl.replace('https://', '')}\n\n📌 This URL NEVER changes!`
          : `⚠️ TEMPORARY URL: ${tunnelUrl}\n\nThis URL changes every restart!\n\nTo get a permanent URL:\n1. Visit https://dash.cloudflare.com\n2. Create a tunnel and get token\n3. Add to config.json`;
        
        new Notification({
          title,
          body,
          timeoutType: 'never'
        }).show();
      }
      
      // Save URL to file for reference
      const urlFile = path.join(__dirname, 'TUNNEL_URL.txt');
      const instructions = isStatic
        ? `This URL is PERMANENT and will never change!\n\nSetup Instructions:\n1. Go to https://vercel.com/your-project/settings/environment-variables\n2. Add: NEXT_PUBLIC_BRIDGE_URL = ${tunnelUrl.replace('https://', '')}\n3. Redeploy your dashboard\n4. Done! This URL is permanent.`
        : `⚠️ WARNING: This URL is TEMPORARY!\nIt will change every time you restart the app.\n\nTo get a PERMANENT URL:\n1. Go to https://dash.cloudflare.com\n2. Click "Zero Trust" → "Networks" → "Tunnels"\n3. Create a tunnel → Get tunnel token\n4. Add to config.json:\n   "cloudflare": {\n     "enabled": true,\n     "tunnel_token": "YOUR_TOKEN_HERE"\n   }\n5. Restart app - you'll get a permanent URL!`;
      
      fs.writeFileSync(urlFile, `Cloudflare Tunnel URL:\n${tunnelUrl}\n\nVercel Environment Variable:\nNEXT_PUBLIC_BRIDGE_URL=${tunnelUrl.replace('https://', '')}\n\n${instructions}`);
      
      // Broadcast to windows
      broadcastToWindows('tunnel-connected', { url: tunnelUrl, type: 'cloudflare', isStatic });
    });
    
    // Handle connection events
    tunnel.once('connected', (connection) => {
      log.info(`Tunnel connected: ${connection.location} (${connection.ip})`);
    });
    
    // Handle tunnel exit
    tunnel.on('exit', (code) => {
      log.warn(`Cloudflare tunnel process exited with code ${code}`);
      cloudflaredProcess = null;
      tunnelUrl = null;
    });
    
    // Handle errors
    tunnel.on('error', (error) => {
      log.error('Cloudflare tunnel error:', error);
    });
    
  } catch (error) {
    log.error('Failed to start Cloudflare tunnel:', error);
    log.error('Will retry on next app start');
  }
}

/**
 * Stop Cloudflare tunnel
 */
async function stopCloudflareTunnel() {
  if (cloudflaredProcess) {
    try {
      cloudflaredProcess.stop();
      log.info('Cloudflare tunnel stopped');
      cloudflaredProcess = null;
      tunnelUrl = null;
    } catch (error) {
      log.error('Error stopping Cloudflare tunnel:', error);
    }
  }
}

/**
 * Connect to Python bridge via WebSocket
 */
function connectToPythonBridge() {
  const wsUrl = `ws://localhost:${config.python_bridge.port}/ws/events`;
  
  log.info(`Connecting to Python bridge at ${wsUrl}...`);
  
  try {
    pythonWs = new WebSocket(wsUrl);
    
    pythonWs.on('open', () => {
      log.info('Connected to Python bridge WebSocket');
      reconnectAttempts = 0;
      
      // Send queued events
      flushEventQueue();
      
      // Notify windows
      broadcastToWindows('python-bridge-connected', { status: 'connected' });
    });
    
    pythonWs.on('message', (data) => {
      try {
        const event = JSON.parse(data);
        handlePythonEvent(event);
      } catch (error) {
        log.error('Error parsing Python event:', error);
      }
    });
    
    pythonWs.on('error', (error) => {
      log.error('Python bridge WebSocket error:', error);
    });
    
    pythonWs.on('close', () => {
      log.warn('Python bridge WebSocket closed');
      pythonWs = null;
      
      // Attempt reconnection
      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        reconnectAttempts++;
        log.info(`Reconnecting to Python bridge (attempt ${reconnectAttempts})...`);
        setTimeout(connectToPythonBridge, 2000 * reconnectAttempts);
      }
      
      broadcastToWindows('python-bridge-disconnected', { status: 'disconnected' });
    });
    
  } catch (error) {
    log.error('Failed to connect to Python bridge:', error);
  }
}

/**
 * Handle events from Python bridge
 */
async function handlePythonEvent(event) {
  log.info('Python event received:', event);
  
  switch (event.type) {
    case 'finger_scanned':
      await handleFingerScanned(event);
      break;
    
    case 'enrollment_started':
      broadcastToWindows('enrollment-started', event);
      break;
    
    case 'enrollment_complete':
      broadcastToWindows('enrollment-complete', event);
      showNotification('Enrollment Complete', `User ${event.user_id} enrolled successfully`);
      break;
    
    case 'enrollment_error':
      broadcastToWindows('enrollment-error', event);
      showNotification('Enrollment Failed', event.error, 'error');
      break;
    
    case 'device_disconnected':
      showNotification('Device Disconnected', 'Fingerprint device lost connection', 'error');
      broadcastToWindows('device-disconnected', event);
      break;
    
    default:
      log.warn('Unknown event type:', event.type);
  }
}

/**
 * Handle finger scan event
 */
async function handleFingerScanned(data) {
  const { user_id, timestamp, punch_type } = data;
  
  log.info(`Finger scanned: user_id=${user_id}, punch_type=${punch_type}`);
  
  try {
    // user_id from fingerprint device is the register_id in members table
    // Search by register_id and get full member data with activations in ONE call
    const apiUrl = config.cloud?.base_url || 'https://bbkdashboard.vercel.app';
    const searchUrl = `${apiUrl}/api/members/search?register_id=${user_id}`;
    log.info(`Searching for member with register_id ${user_id} at: ${searchUrl}`);
    
    const searchResponse = await fetch(searchUrl);
    
    log.info(`Search response status: ${searchResponse.status}`);
    
    if (!searchResponse.ok) {
      const errorText = await searchResponse.text();
      log.error(`Failed to search member by register_id ${user_id}: ${searchResponse.status} - ${errorText}`);
      showNotification('Error', 'Member not found', 'error');
      return;
    }
    
    const searchResult = await searchResponse.json();
    log.info(`Search result:`, JSON.stringify(searchResult, null, 2));
    
    if (!searchResult.success || !searchResult.data || searchResult.data.length === 0) {
      log.error(`No member found with register_id ${user_id}`);
      showNotification('Access Denied', 'Member not found', 'error');
      return;
    }
    
    const fullMember = searchResult.data[0];
    const memberId = fullMember.id;
    log.info(`Found member ID: ${memberId} for register_id: ${user_id}`);
    
    // Process member validation and access control
    await processValidMember(fullMember, user_id, timestamp);
    
  } catch (error) {
    log.error('Error handling finger scan:', error);
    showNotification('Error', 'Failed to process attendance', 'error');
  }
}

/**
 * Process valid member and check access
 */
async function processValidMember(fullMember, registerId, timestamp) {
  const memberId = fullMember.id;
  
  // Get the most recent registration with activation data
  const registrations = fullMember.registration_gym_members || [];
  const latestRegistration = registrations.length > 0 ? registrations[0] : null;
  
  // Get activation from the registration (contains end_date)
  const activation = latestRegistration?.activation || null;
  
  // Check if member has valid activation
  let isValid = false;
  let accessMessage = '';
  
  if (activation && activation.end_date) {
    const endDate = new Date(activation.end_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    endDate.setHours(0, 0, 0, 0);
    
    isValid = endDate >= today;
    
    if (isValid) {
      accessMessage = 'Access Granted - Welcome!';
      log.info(`Member ${memberId} (register_id: ${registerId}) has valid access until ${activation.end_date}`);
      
      // Open door for valid members
      await openDoor();
    } else {
      accessMessage = 'Access Denied - Membership Expired';
      log.warn(`Member ${memberId} (register_id: ${registerId}) membership expired on ${activation.end_date}`);
    }
  } else {
    accessMessage = 'Access Denied - No Active Membership';
    log.warn(`Member ${memberId} (register_id: ${registerId}) has no activation record`);
  }
  
  // Mark attendance regardless of validity (for tracking)
  if (latestRegistration) {
    await markAttendance(memberId, latestRegistration.id);
  }
  
  // Prepare member data to display
  const memberData = {
    user_id: memberId,
    register_id: registerId,
    name: `${fullMember.fname} ${fullMember.lname}`,
    phone: fullMember.telephone_no,
    expiry_date: activation?.end_date || 'N/A',
    is_valid: isValid,
    message: accessMessage,
    timestamp
  };
  
  // Show popup on all screens (for both valid and expired)
  broadcastToWindows('show-member-popup', memberData);
  
  // Auto-close after 5 seconds
  setTimeout(() => {
    broadcastToWindows('hide-member-popup');
  }, 5000);
  
  // Show notification
  showNotification(
    isValid ? 'Access Granted' : 'Access Denied',
    `${memberData.name} - ${accessMessage}`,
    isValid ? 'info' : 'error'
  );
}

/**
 * Mark attendance (check-in or check-out)
 */
async function markAttendance(memberId, registrationId) {
  try {
    const apiUrl = config.cloud?.base_url || 'https://bbkdashboard.vercel.app';
    const attendanceUrl = `${apiUrl}/api/attendance/mark`;
    
    log.info(`Marking attendance for member ${memberId}, registration ${registrationId}`);
    
    // Use native http/https POST
    const url = new URL(attendanceUrl);
    const protocol = url.protocol === 'https:' ? https : http;
    const postData = JSON.stringify({
      member_id: memberId,
      registration_id: registrationId
    });
    
    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    return new Promise((resolve, reject) => {
      const req = protocol.request(options, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            const result = JSON.parse(data);
            if (result.success) {
              log.info(`Attendance marked: ${result.action} at ${new Date().toLocaleTimeString()}`);
              resolve(result);
            } else {
              log.error('Failed to mark attendance:', result.error);
              resolve(null);
            }
          } catch (error) {
            log.error('Error parsing attendance response:', error);
            resolve(null);
          }
        });
      });
      
      req.on('error', (error) => {
        log.error('Error marking attendance:', error);
        resolve(null); // Don't fail the door opening if attendance fails
      });
      
      req.write(postData);
      req.end();
    });
  } catch (error) {
    log.error('Error in markAttendance:', error);
    return null;
  }
}

/**
 * Open door by sending command to fingerprint device
 */
async function openDoor() {
  try {
    if (!pythonWs || pythonWs.readyState !== WebSocket.OPEN) {
      log.error('Cannot open door: Python bridge not connected');
      return;
    }
    
    log.info('Opening door...');
    
    // Send door control command to Python bridge
    pythonWs.send(JSON.stringify({
      action: 'control_door',
      data: {
        action: 'open',
        duration: config.door?.open_duration || 3
      }
    }));
    
    log.info('Door open command sent');
  } catch (error) {
    log.error('Error opening door:', error);
  }
}

/**
 * Broadcast message to all renderer windows
 */
function broadcastToWindows(channel, data) {
  if (employeeWindow) {
    employeeWindow.webContents.send(channel, data);
  }
  if (memberWindow) {
    memberWindow.webContents.send(channel, data);
  }
}

/**
 * Show system notification
 */
function showNotification(title, body, type = 'info') {
  if (Notification.isSupported()) {
    new Notification({ title, body }).show();
  }
  log.info(`[Notification] ${title}: ${body}`);
}

/**
 * Send command to Python bridge
 */
function sendToPythonBridge(message) {
  if (pythonWs && pythonWs.readyState === WebSocket.OPEN) {
    pythonWs.send(JSON.stringify(message));
    log.info('Sent to Python bridge:', message);
  } else {
    log.warn('Python bridge not connected, queuing message');
    eventQueue.push(message);
  }
}

/**
 * Flush queued events when connection restored
 */
function flushEventQueue() {
  if (eventQueue.length === 0) return;
  
  log.info(`Flushing ${eventQueue.length} queued events...`);
  
  while (eventQueue.length > 0) {
    const event = eventQueue.shift();
    sendToPythonBridge(event);
  }
}

/**
 * Create application menu
 */
function createMenu() {
  const template = [
    {
      label: 'File',
      submenu: [
        {
          label: 'Dashboard',
          accelerator: 'Ctrl+D',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url);
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Settings',
          accelerator: 'Ctrl+,',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/dashboard/settings');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Exit',
          accelerator: 'Ctrl+Q',
          click: () => {
            app.quit();
          }
        }
      ]
    },
    {
      label: 'View',
      submenu: [
        {
          label: 'Members',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/dashboard/members');
            }
          }
        },
        {
          label: 'Registrations',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/dashboard/registrations');
            }
          }
        },
        {
          label: 'Attendance',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/dashboard/attendance');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Promotional Media',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/dashboard/member-screen');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Member Kiosk',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/member-kiosk');
            }
          }
        },
        {
          label: 'Member Screen',
          click: () => {
            if (employeeWindow) {
              employeeWindow.loadURL(config.screens.employee.url + '/member-screen');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Reload',
          accelerator: 'Ctrl+R',
          click: (item, focusedWindow) => {
            if (focusedWindow) {
              focusedWindow.reload();
            }
          }
        },
        {
          label: 'Toggle DevTools',
          accelerator: 'Ctrl+Shift+I',
          click: (item, focusedWindow) => {
            if (focusedWindow) {
              focusedWindow.webContents.toggleDevTools();
            }
          }
        }
      ]
    },
    {
      label: 'Hardware',
      submenu: [
        {
          label: 'Fingerprint Device',
          submenu: [
            {
              label: 'Reconnect',
              click: () => {
                sendToPythonBridge({
                  type: 'command',
                  action: 'reconnect_device',
                  request_id: Date.now().toString()
                });
              }
            },
            {
              label: 'Get Users',
              click: () => {
                sendToPythonBridge({
                  type: 'command',
                  action: 'get_users',
                  request_id: Date.now().toString()
                });
              }
            }
          ]
        },
        { type: 'separator' },
        {
          label: 'Test Door Lock',
          click: () => {
            sendToPythonBridge({
              type: 'command',
              action: 'open_door',
              payload: { duration: 5 },
              request_id: Date.now().toString()
            });
            showNotification('Door Test', 'Opening door for 5 seconds...');
          }
        },
        { type: 'separator' },
        {
          label: 'Gym-Bridge Status',
          click: () => {
            // Open health check in browser
            require('electron').shell.openExternal(`http://localhost:${config.python_bridge.port}/health`);
          }
        }
      ]
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Documentation',
          click: () => {
            require('electron').shell.openExternal('https://github.com/yourusername/bbk-hardware-bridge');
          }
        },
        { type: 'separator' },
        {
          label: 'About',
          click: () => {
            require('electron').dialog.showMessageBox({
              type: 'info',
              title: 'About BBK Hardware Bridge',
              message: 'BBK Gym Hardware Bridge v1.0.0',
              detail: 'Desktop application for managing gym hardware devices with cloud integration.'
            });
          }
        }
      ]
    }
  ];
  
  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// ==================== IPC Handlers ====================

/**
 * Handle fingerprint enrollment request from renderer
 */
ipcMain.handle('enroll-fingerprint', async (event, { user_id, finger_id }) => {
  log.info(`Enrollment requested for user ${user_id}, finger ${finger_id}`);
  
  return new Promise((resolve) => {
    const request_id = Date.now().toString();
    
    // Send command to Python
    sendToPythonBridge({
      type: 'command',
      action: 'enroll_fingerprint',
      payload: { user_id, finger_id },
      request_id
    });
    
    // Listen for response
    // In production, you'd set up a proper request/response handler
    setTimeout(() => {
      resolve({ success: true, message: 'Enrollment started' });
    }, 1000);
  });
});

/**
 * Handle door open request from renderer
 */
ipcMain.handle('open-door', async (event, { duration = 5 }) => {
  log.info(`Door open requested for ${duration} seconds`);
  
  sendToPythonBridge({
    type: 'command',
    action: 'open_door',
    payload: { duration },
    request_id: Date.now().toString()
  });
  
  return { success: true, message: `Door will open for ${duration} seconds` };
});

/**
 * Handle door close request from renderer
 */
ipcMain.handle('close-door', async (event) => {
  log.info('Door close requested');
  
  sendToPythonBridge({
    type: 'command',
    action: 'close_door',
    request_id: Date.now().toString()
  });
  
  return { success: true, message: 'Door closing' };
});

/**
 * Get hardware status
 */
ipcMain.handle('get-hardware-status', async (event) => {
  return {
    python_bridge: {
      connected: pythonWs && pythonWs.readyState === WebSocket.OPEN,
      reconnect_attempts: reconnectAttempts
    },
    fingerprint: {
      configured: !!config.hardware.fingerprint.ip
    },
    doorlock: {
      configured: !!config.hardware.doorlock.port
    }
  };
});

// ==================== App Lifecycle ====================

app.whenReady().then(() => {
  log.info('App ready, initializing...');
  
  // Load config
  loadConfig();
  
  // Create windows
  createEmployeeWindow();
  createMemberWindow();
  
  // Create menu
  createMenu();
  
  // Start Python bridge
  startPythonBridge();
  
  log.info('Initialization complete');
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createEmployeeWindow();
  }
});

app.on('before-quit', async () => {
  log.info('App quitting, cleaning up...');
  
  // Stop Cloudflare tunnel
  await stopCloudflareTunnel();
  
  // Close WebSocket
  if (pythonWs) {
    pythonWs.close();
  }
  
  // Kill Python process gracefully
  if (pythonProcess) {
    try {
      pythonProcess.kill('SIGTERM');
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (err) {
      log.error('Error killing python process:', err);
    }
  }
  
  // Force kill any remaining BBK-Bridge processes
  await killExistingBridge();
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  log.error('Uncaught exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  log.error('Unhandled rejection at:', promise, 'reason:', reason);
});
