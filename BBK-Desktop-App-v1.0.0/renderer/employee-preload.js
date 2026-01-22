/**
 * Employee Screen Preload Script
 * Exposes safe APIs to employee dashboard renderer process
 */

const { contextBridge, ipcRenderer } = require('electron');

// Expose hardware API to renderer
contextBridge.exposeInMainWorld('hardware', {
  // Fingerprint operations
  enrollFingerprint: (userId, fingerId = 1) => 
    ipcRenderer.invoke('enroll-fingerprint', { user_id: userId, finger_id: fingerId }),
  
  // Door lock operations
  openDoor: (duration = 5) => 
    ipcRenderer.invoke('open-door', { duration }),
  
  closeDoor: () => 
    ipcRenderer.invoke('close-door'),
  
  // Hardware status
  getStatus: () => 
    ipcRenderer.invoke('get-hardware-status'),
  
  // Event listeners
  on: (channel, callback) => {
    const validChannels = [
      'finger-scanned',
      'enrollment-started',
      'enrollment-complete',
      'enrollment-error',
      'device-disconnected',
      'python-bridge-connected',
      'python-bridge-disconnected'
    ];
    
    if (validChannels.includes(channel)) {
      ipcRenderer.on(channel, (event, ...args) => callback(...args));
    }
  },
  
  removeListener: (channel, callback) => {
    ipcRenderer.removeListener(channel, callback);
  }
});

// Expose app info
contextBridge.exposeInMainWorld('app', {
  version: '1.0.0',
  name: 'BBK Hardware Bridge'
});

console.log('Employee preload script loaded');
