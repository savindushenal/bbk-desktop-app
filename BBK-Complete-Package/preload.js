const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electron', {
  // Member screen controls
  openMemberScreen: () => ipcRenderer.invoke('open-member-screen'),
  
  // Gym-Bridge backend status
  checkGymBridge: () => ipcRenderer.invoke('check-gym-bridge'),
  
  // Platform information
  platform: process.platform,
  isElectron: true,
  
  // App version
  version: require('../package.json').version
});

// Notify renderer when app is ready
window.addEventListener('DOMContentLoaded', () => {
  console.log('BBK Gym Management Desktop App - Ready');
});
