// import { ethers } from "https://cdn.ethers.io/lib/ethers-5.2.esm.min.js";

const CONTRACT_ADDRESS = "0x6F0fDFBa064627156e6c2582a6bbb75D83907476";
// const CONTRACT_ADDRESS = "0x9251dc15fe10f3b0176ed5fbb97fa93baa739075";

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

                // check if account is member
                const memberAddresses = await contract.viewMemberAddresses();
                if (memberAddresses.includes(account)) {
                    const connectedScreen = document.getElementById("connectedScreen");
                    connectedScreen.style.display = "block";
                    const myNameDiv = document.getElementById("myName");
                    const myName = await contract.viewMemberName(account);
                    myNameDiv.innerHTML = `Logged in as: ${myName}`;
                } else {
                    const signUpForm = document.getElementById("signUp");
                    signUpForm.style.display = "block";
                    signUpForm.addEventListener("submit", async (event) => {
                        // send 0.001eth with transaction
                        event.preventDefault();
                        const name = document.getElementById("nameInput").value;
                        const signUp = await contract.requestToJoin(name, { value: ethers.utils.parseEther("0.001") });
                        console.log("signUp: ", signUp);
                        const connectedScreen = document.getElementById("connectedScreen");
                        connectedScreen.style.display = "block";
                        const myNameDiv = document.getElementById("myName");
                        myNameDiv.innerHTML = `Logged in as: ${name}`;
                    });
                }


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


                // create list of events
                const createEventForm = document.getElementById("createEvent");
                createEventForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const eventTitle = document.getElementById("createEventTitle").value;
                    const eventDescription = document.getElementById("createEventDescription").value;
                    const newEvent = await contract.createEvent(eventTitle, eventDescription);
                    console.log("newEvent: ", newEvent);
                });

                const eventsList = document.getElementById("eventList");
                const events = await contract.viewAllEvents();
                console.log("events: ", events);
                for (const daoEventNum in events) {
                    const daoEvent = events[daoEventNum];
                    console.log("daoEvent: ", daoEvent);
                    const li = document.createElement("li");
                    let title = document.createElement('strong');
                    title.innerHTML = daoEvent.title;
                    li.appendChild(title);
                    let description = document.createElement('p');
                    description.innerHTML = daoEvent.description;
                    li.appendChild(description);
                    // join event button
                    let joinEventButton = document.createElement("button");
                    joinEventButton.innerHTML = "Join Event";
                    joinEventButton.addEventListener("click", async () => {
                        const joinEvent = await contract.joinEvent(event.id);
                        console.log("joinEvent: ", joinEvent);
                    });
                    li.appendChild(joinEventButton);

                    let attendeesLabel = document.createElement('p');
                    attendeesLabel.innerHTML = "Attendees: ";
                    li.appendChild(attendeesLabel);

                    let attendeesString = "";
                    for (const memberNum in daoEvent.members) {
                        const member = daoEvent.members[memberNum];
                        console.log("member: ", member)
                        const memberName = await contract.viewMemberName(member);
                        console.log(memberName);
                        attendeesString = attendeesString + memberName + ", ";
                    }
                    console.log("attendeesString: ", attendeesString);
                    attendeesString = attendeesString.slice(0, -2);
                    console.log("attendeesString: ", attendeesString);
                    let attendees = document.createElement("span");
                    attendees.innerHTML = attendeesString
                    li.appendChild(attendees);

                    eventsList.appendChild(li);
                }



            } catch (error) {
                console.error(error);
            }
        });

    } else {
        console.log("No Ethereum browser extension detected, install MetaMask on desktop or visit from a dApp browser on mobile.");
    }
});
