const CONTRACT_ADDRESS = "TODO";
const CONTRACT_ABI = [];


window.addEventListener("load", async () => {
    // Modern dapp browsers...
    if (window.ethereum) {
        window.web3 = new Web3(ethereum);
        try {
            // Request account access if needed
            await ethereum.enable();
        } catch (error) {
            // User denied account access...
            console.error("User denied account access")
        }
    }
    // Non-dapp browsers
    else {
        console.error("Non-Ethereum browser detected. You should consider trying MetaMask!");
    }
    startApp();
});

async function startApp() {
    const accounts = await web3.eth.getAccounts();

    const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);

    document.getElementById("signupButton").addEventListener("click", async () => {
        const name = document.getElementById("name").value;
        await contract.methods.sign_up(name).send({ from: accounts[0] });
    });

    document.getElementById("voteButton").addEventListener("click", async () => {
        const name = document.getElementById("name").value;
        await contract.methods.vote(name).send({ from: accounts[0] });
    });

    // Get the voters list from the blockchain
    const list = await contract.methods.get_list().call({ from: accounts[0] });
    document.getElementById("list").value = list.join("\n");
}