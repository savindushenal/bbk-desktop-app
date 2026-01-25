/**
 * Member Screen Preload Script
 * Exposes limited APIs to member kiosk renderer process
 */

const { contextBridge, ipcRenderer } = require('electron');

// Expose minimal API for member screen
contextBridge.exposeInMainWorld('memberScreen', {
  // Event listeners only (no commands)
  on: (channel, callback) => {
    const validChannels = [
      'show-member-info',
      'hide-member-info',
      'finger-scanned',
      'show-member-popup',
      'hide-member-popup'
    ];
    
    if (validChannels.includes(channel)) {
      ipcRenderer.on(channel, (event, ...args) => callback(...args));
    }
  },
  
  removeListener: (channel, callback) => {
    ipcRenderer.removeListener(channel, callback);
  }
});

console.log('Member screen preload script loaded');
