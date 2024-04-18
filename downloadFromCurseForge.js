console.log("Received arguments: ", process.argv);

const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const fsPromises = require('fs').promises;
const fs = require('fs');
const https = require('https');
const path = require('path');
const unzipper = require('unzipper');

puppeteer.use(StealthPlugin());

let isDownloadStarted = false;

async function unzipFile(filePath, destDir) {
    return new Promise((resolve, reject) => {
        fs.createReadStream(filePath)
            .pipe(unzipper.Extract({ path: destDir }))
            .on('close', resolve)
            .on('error', reject);
    });
}

async function moveFilesFromSubfolder(destDir) {
    const dirs = await fsPromises.readdir(destDir, { withFileTypes: true });
    const subfolderDirent = dirs.find(dirent => dirent.isDirectory());
    if (!subfolderDirent) {
        console.error('No subfolder found in destination directory.');
        return;
    }
    
    const subfolderPath = path.join(destDir, subfolderDirent.name);
    const files = await fsPromises.readdir(subfolderPath);
    
    for (const file of files) {
        const fromPath = path.join(subfolderPath, file);
        const toPath = path.join(destDir, file);
        await fsPromises.rename(fromPath, toPath);
    }

    // Remove the now-empty subfolder
    await fsPromises.rmdir(subfolderPath, { recursive: true });
}

(async () => {
    try {
        if (process.argv.length < 4) {
            console.error('Please provide a URL and Chrome path as command line arguments.');
            process.exit(1);
        }

        const targetURL = process.argv[2];
        const chromePath = process.argv[3];
        const folderStructure = '/minecraft';
        const minecraftServerPath = '/minecraft/server';

        if (!fs.existsSync(folderStructure)) {
            fs.mkdirSync(folderStructure);
        }

        if (!fs.existsSync(minecraftServerPath)) {
            fs.mkdirSync(minecraftServerPath);
        }

        const browser = await puppeteer.launch({
            executablePath: chromePath,
            headless: true,
            args: ['--no-sandbox', '--disable-setuid-sandbox'],
        });

        const page = await browser.newPage();
        await page.setRequestInterception(true);

        page.on('request', async (request) => {
            if (isDownloadStarted) {
                request.abort();
                return;
            }

            if (request.url().endsWith('.zip')) {
                isDownloadStarted = true;

                const urlParts = new URL(request.url());
                const fileName = path.basename(urlParts.pathname);
                const downloadPath = path.join(folderStructure, fileName);
                const file = fs.createWriteStream(downloadPath);

                https.get(request.url(), (response) => {
                    response.pipe(file);

                    file.on('finish', async () => {
                        file.close(async () => {
                            console.log('Download complete');
                            console.log('DownloadedFilePath:', downloadPath);

                            await unzipFile(downloadPath, minecraftServerPath);
                            console.log('Unzip complete');

                            await moveFilesFromSubfolder(minecraftServerPath);
                            console.log('Files moved to /minecraft/server');

                            // Clean up: Remove the ZIP file
                            await fsPromises.unlink(downloadPath);
                            console.log('Cleanup complete.');

                            await browser.close();
                            process.exit(0);
                        });
                    });
                });
            } else {
                request.continue();
            }
        });

        await page.goto(targetURL, { timeout: 0 });
        await page.waitForTimeout(10000);

        await browser.close();
    } catch (error) {
        if (error.message && error.message.includes("Navigation failed because browser has disconnected")) {
            console.warn("Browser disconnected. Treating as a soft error.");
            process.exit(0);
        } else {
            console.error('An error occurred:', error);
            process.exit(1);
        }
    }
})();
