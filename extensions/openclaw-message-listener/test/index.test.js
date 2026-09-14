// Basic test to validate middleware structure
import fs from 'fs';
import path from 'path';

// Test that all required files exist
console.log('Testing OpenClaw Message Listener structure...');

const requiredFiles = [
  './src/index.js',
  './openclaw.plugin.json',
  './package.json',
  './README.md'
];

let allFilesExist = true;

for (const file of requiredFiles) {
  const filePath = path.join(process.cwd(), file);
  if (fs.existsSync(filePath)) {
    console.log(`✓ ${file} exists`);
  } else {
    console.log(`✗ ${file} missing`);
    allFilesExist = false;
  }
}

if (allFilesExist) {
  console.log('\n✓ All required files exist');
  
  // Check if the main index.js has the expected exports
  try {
    const indexContent = fs.readFileSync(path.join(process.cwd(), './src/index.js'), 'utf8');
    
    if (indexContent.includes('definePluginEntry')) {
      console.log('✓ Correctly exports a plugin entry');
    } else {
      console.log('✗ Missing definePluginEntry export');
      allFilesExist = false;
    }
    
    if (indexContent.includes('before_agent_run')) {
      console.log('✓ Contains before_agent_run hook');
    } else {
      console.log('✗ Missing before_agent_run hook');
      allFilesExist = false;
    }
    
    if (indexContent.includes('after_agent_run')) {
      console.log('✓ Contains after_agent_run hook');
    } else {
      console.log('✗ Missing after_agent_run hook');
      allFilesExist = false;
    }
  } catch (error) {
    console.log(`✗ Error reading index.js: ${error.message}`);
    allFilesExist = false;
  }
}

if (allFilesExist) {
  console.log('\n🎉 OpenClaw Message Listener validation passed!');
  console.log('\nTo use this middleware:');
  console.log('1. Place this folder in your OpenClaw plugins directory');
  console.log('2. Add the path to openclaw.json under plugins.load.paths');
  console.log('3. Restart OpenClaw');
} else {
  console.log('\n❌ Validation failed. Please check the above errors.');
  process.exit(1);
}