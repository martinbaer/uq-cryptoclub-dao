import { ethers } from "./ethers.min.js";

document.addEventListener('DOMContentLoaded', async () => {

    if (typeof window.ethereum !== 'undefined') {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const connectButton = document.getElementById('connectButton');
        const accountElement = document.getElementById('account');

        connectButton.addEventListener('click', async () => {
            try {
                console.log("connected: ", window.ethereum.isConnected())
                // Request account access
                await window.ethereum.request({ method: 'eth_requestAccounts' });

                // Fetch account from provider
                const signer = await provider.getSigner();
                console.log("signer: ", signer);
                const account = await signer.getAddress();
                accountElement.innerHTML = `Connected: ${account}`;
            } catch (error) {
                console.error(error);
            }
        });
    } else {
        console.log('No Ethereum browser extension detected, install MetaMask on desktop or visit from a dApp browser on mobile.');
    }
});
