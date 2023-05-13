// import { ethers } from "https://cdn.ethers.io/lib/ethers-5.2.esm.min.js";

const CONTRACT_ADDRESS = "0x6F0fDFBa064627156e6c2582a6bbb75D83907476";
// read from contract_abi.json

console.log(ethers);

document.addEventListener("DOMContentLoaded", async () => {

    if (typeof window.ethereum !== "undefined") {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const connectMetamaskButton = document.getElementById("connectMetamaskButton");

        connectMetamaskButton.addEventListener("click", async () => {
            try {
                console.log("connected: ", window.ethereum.isConnected())
                // Request account access
                await window.ethereum.request({ method: "eth_requestAccounts" });

                // Fetch account from provider
                const signer = await provider.getSigner();
                console.log("signer: ", signer);
                const account = await signer.getAddress();

                // hide connect button
                connectMetamaskButton.style.display = "none";
                // change text of connectMetamaskLabel
                const connectMetamaskLabel = document.getElementById("connectMetamaskLabel");
                connectMetamaskLabel.innerHTML = `Connected to account: ${account}`;

                // Fetch contract
                const contract_abi_file = await fetch("./contract_abi.json");
                const contract_abi = await contract_abi_file.json();

                // create contract instance
                const contract = new ethers.Contract(CONTRACT_ADDRESS, contract_abi, signer);
                console.log("contract: ", contract);
                // const contract_owner = await contract.owner();
                // console.log("contract_owner: ", contract_owner);

                // call viewMemberNames
                const members = await contract.viewMemberNames();
                console.log("members: ", members);
                // create list of members
                const membersList = document.getElementById("membersList");
                members.forEach(member => {
                    const li = document.createElement("li");
                    li.innerHTML = member;
                    membersList.appendChild(li);
                }
                );

            } catch (error) {
                console.error(error);
            }
        });

    } else {
        console.log("No Ethereum browser extension detected, install MetaMask on desktop or visit from a dApp browser on mobile.");
    }
});
