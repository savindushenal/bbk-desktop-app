const { app, BrowserWindow, Menu, ipcMain, dialog } = require('electron');
const path = require('path');
const isDev = process.env.NODE_ENV === 'development';

let mainWindow;
let memberScreenWindow;
let memberKioskWindow;

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1200,
    minHeight: 700,
    title: 'BBK Gym Management',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    autoHideMenuBar: false,
    backgroundColor: '#0f172a'
  });

  // Load the deployed dashboard
  const startUrl = 'https://bbkdashboard.vercel.app/';

  mainWindow.loadURL(startUrl);

  // Open DevTools in development
  if (isDev) {
    mainWindow.webContents.openDevTools();
  }

  // Create application menu
  createMenu();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Handle navigation
  mainWindow.webContents.on('did-fail-load', () => {
    if (isDev) {
      setTimeout(() => {
        mainWindow.loadURL(startUrl);
      }, 1000);
    }
  });
}

function createMemberScreenWindow() {
  if (memberScreenWindow) {
    memberScreenWindow.focus();
    return;
  }

  memberScreenWindow = new BrowserWindow({
    width: 1920,
    height: 1080,
    fullscreen: true,
    title: 'Member Screen',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#000000',
    autoHideMenuBar: true,
    kiosk: true
  });

  const url = 'https://bbkdashboard.vercel.app/member-screen';

  memberScreenWindow.loadURL(url);

  memberScreenWindow.on('closed', () => {
    memberScreenWindow = null;
  });
}

function createMemberKioskWindow() {
  if (memberKioskWindow) {
    memberKioskWindow.focus();
    return;
  }

  memberKioskWindow = new BrowserWindow({
    width: 1920,
    height: 1080,
    fullscreen: true,
    title: 'Member Self-Registration Kiosk',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    backgroundColor: '#1e3a8a',
    autoHideMenuBar: true,
    kiosk: true
  });

  const url = 'https://bbkdashboard.vercel.app/member-kiosk';

  memberKioskWindow.loadURL(url);

  // Allow Escape key to exit kiosk mode
  memberKioskWindow.webContents.on('before-input-event', (event, input) => {
    if (input.key === 'Escape') {
      memberKioskWindow.setKiosk(false);
      memberKioskWindow.setFullScreen(false);
    }
  });

  memberKioskWindow.on('closed', () => {
    memberKioskWindow = null;
  });
}

function createMenu() {
  const template = [
    {
      label: 'File',
      submenu: [
        {
          label: 'Dashboard',
          accelerator: 'Ctrl+D',
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL(isDev ? 'http://localhost:3000/dashboard' : 'file://...');
            }
          }
        },
        {
          label: 'Member Screen (Kiosk)',
          accelerator: 'Ctrl+M',
          click: createMemberScreenWindow
        },
        { type: 'separator' },
        {
          label: 'Settings',
          accelerator: 'Ctrl+,',
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/settings');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Exit',
          accelerator: 'Alt+F4',
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
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/members');
            }
          }
        },
        {
          label: 'Registrations',
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/registrations');
            }
          }
        },
        {
          label: 'Attendance',
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/attendance');
            }
          }
        },
        {
          label: 'Promotional Media',
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/member-screen');
            }
          }
        },
        { type: 'separator' },
        {
          label: 'Member Kiosk (Self Registration)',
          click: () => {
            createMemberKioskWindow();
          }
        },
        {
          label: 'Member Screen (Display)',
          click: () => {
            createMemberScreenWindow();
          }
        },
        { type: 'separator' },
        {
          label: 'Reload',
          accelerator: 'Ctrl+R',
          click: () => {
            if (mainWindow) {
              mainWindow.reload();
            }
          }
        },
        {
          label: 'Toggle Developer Tools',
          accelerator: 'F12',
          click: () => {
            if (mainWindow) {
              mainWindow.webContents.toggleDevTools();
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
          click: () => {
            if (mainWindow) {
              mainWindow.loadURL('https://bbkdashboard.vercel.app/dashboard/devices');
            }
          }
        },
        {
          label: 'Test Door Lock',
          click: async () => {
            try {
              const response = await fetch('http://127.0.0.1:8000/api/doorlock/open', {
                method: 'POST'
              });
              const data = await response.json();
              dialog.showMessageBox(mainWindow, {
                type: 'info',
                title: 'Door Lock Test',
                message: data.message || 'Door lock activated',
                buttons: ['OK']
              });
            } catch (error) {
              dialog.showMessageBox(mainWindow, {
                type: 'error',
                title: 'Error',
                message: 'Failed to connect to gym-bridge backend. Make sure it is running.',
                buttons: ['OK']
              });
            }
          }
        },
        {
          label: 'Check Gym-Bridge Status',
          click: async () => {
            try {
              const response = await fetch('http://127.0.0.1:8000/health');
              const data = await response.json();
              dialog.showMessageBox(mainWindow, {
                type: 'info',
                title: 'Gym-Bridge Status',
                message: `Status: ${data.status}\nVersion: ${data.version}`,
                buttons: ['OK']
              });
            } catch (error) {
              dialog.showMessageBox(mainWindow, {
                type: 'error',
                title: 'Connection Error',
                message: 'Gym-Bridge backend is not running. Please start it first.',
                buttons: ['OK']
              });
            }
          }
        }
      ]
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Quick Start Guide',
          click: () => {
            // Open documentation
            require('electron').shell.openExternal('file://' + path.join(__dirname, 'BUILD_GUIDE.md'));
          }
        },
        {
          label: 'About',
          click: () => {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'About BBK Gym Management',
              message: 'BBK Gym Management System\nVersion 1.0.0\n\nComplete gym management solution with member tracking, attendance, and hardware integration.',
              buttons: ['OK']
            });
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// IPC Handlers for renderer communication
ipcMain.handle('open-member-screen', () => {
  createMemberScreenWindow();
});

ipcMain.handle('check-gym-bridge', async () => {
  try {
    const response = await fetch('http://127.0.0.1:8000/health');
    const data = await response.json();
    return { success: true, data };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// App lifecycle
app.whenReady().then(() => {
  createMainWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
