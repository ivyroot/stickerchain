const fs = require('fs');
const { spawn, execSync } = require('child_process');
const path = require('path');

// Find forge path
let forgePath;
try {
    forgePath = execSync('which forge').toString().trim();
} catch (error) {
    console.error('Error: forge command not found. Please ensure forge is installed and in your PATH');
    process.exit(1);
}

// Read the JSON file
const jsonPath = path.join(__dirname, 'SourceStickerDesigns.json');
const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

// Get the RPC URL from environment
const rpcUrl = process.env.STAGING_RPC;
if (!rpcUrl) {
    console.error('Error: STAGING_RPC environment variable is not set');
    process.exit(1);
}

// Function to run forge script for a single sticker
async function publishSticker(metadataCID, imageCID) {
    return new Promise((resolve, reject) => {
        const command = forgePath;
        const args = [
            'script',
            '--chain-id', '84532',
            '--rpc-url', rpcUrl,
            '--account', 'deployer',
            '11_PublishASticker.sol:PublishASticker',
            '--sig', 'run(string,string)',
            metadataCID,
            imageCID,
            '--broadcast'
        ];

        console.log(`\nPublishing sticker with metadata CID: ${metadataCID}`);
        console.log(`Image CID: ${imageCID}`);
        console.log(`Command: ${command} ${args.join(' ')}`);

        const forgeProcess = spawn(command, args, {
            stdio: 'inherit',
            shell: false  // Disable shell interpretation
        });

        forgeProcess.on('close', (code) => {
            if (code === 0) {
                console.log(`Successfully published sticker with metadata CID: ${metadataCID}`);
                resolve();
            } else {
                console.error(`Failed to publish sticker with metadata CID: ${metadataCID}`);
                reject(new Error(`Process exited with code ${code}`));
            }
        });

        forgeProcess.on('error', (err) => {
            console.error(`Error running forge script: ${err.message}`);
            reject(err);
        });
    });
}

// Main function to process all stickers
async function main() {
    const stickers = jsonData.data;
    console.log(`Found ${stickers.length} stickers to publish`);

    for (let i = 0; i < stickers.length; i++) {
        const sticker = stickers[i];
        try {
            await publishSticker(sticker.metadataCID, sticker.imageCID);
            console.log(`Progress: ${i + 1}/${stickers.length}`);
        } catch (error) {
            console.error(`Error processing sticker ${i + 1}:`, error.message);
            // Continue with next sticker even if one fails
        }
    }

    console.log('Finished processing all stickers');
}

// Run the main function
main().catch(console.error);
