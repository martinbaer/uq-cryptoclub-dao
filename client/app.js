const CONTRACT_ADDRESS = "0x85739Bc42b27A95C5695781e4380Aa89F631Ef6D";

document.addEventListener("DOMContentLoaded", async () => {

    if (typeof window.ethereum !== "undefined") {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const connectMetamaskButton = document.getElementById("connectMetamaskButton");

        connectMetamaskButton.addEventListener("click", async () => {
            try {
                console.log("connected: ", window.ethereum.isConnected())
                await window.ethereum.request({ method: "eth_requestAccounts" });

                const signer = await provider.getSigner();
                console.log("signer: ", signer);
                const account = await signer.getAddress();

                connectMetamaskButton.style.display = "none";
                const connectMetamaskLabel = document.getElementById("connectMetamaskLabel");
                connectMetamaskLabel.innerHTML = `Connected to account: ${account}`;

                const contract_abi_file = await fetch("./contract_abi.json");
                const contract_abi = await contract_abi_file.json();

                const contract = new ethers.Contract(CONTRACT_ADDRESS, contract_abi, signer);
                console.log("contract: ", contract);

                // DISPLAY PRESIDENT
                // <p id="president"></p>
                const president = await contract.viewPresident();
                console.log("president: ", president);
                const presidentDiv = document.getElementById("president");
                presidentDiv.innerHTML = `President: ${president.addressOfMember} - ${president.name}`;

                // CREATE MEMBER LIST
                const members = await contract.viewAllMembers();
                console.log("members: ", members);
                if (members.map(member => member.addressOfMember).includes(account)) {
                    // reveal connected screen
                    const connectedScreen = document.getElementById("connectedScreen");
                    connectedScreen.style.display = "block";
                    const myNameDiv = document.getElementById("myName");
                    // add class="subtitle" to myNameDDiv
                    const myName = members.filter(member => member.addressOfMember == account)[0].name;
                    myNameDiv.innerHTML = `Registered as member: ${myName}`;
                } else {
                    const signUpForm = document.getElementById("signUp");
                    signUpForm.style.display = "block";
                    signUpForm.addEventListener("submit", async (event) => {
                        event.preventDefault();
                        const name = document.getElementById("nameInput").value;
                        const signUp = await contract.requestToJoin(name, { value: ethers.utils.parseEther("0.001") });
                        console.log("signUp: ", signUp);
                        const connectedScreen = document.getElementById("connectedScreen");
                        connectedScreen.style.display = "block";
                        const myNameDiv = document.getElementById("myName");
                        myNameDiv.innerHTML = `Registered as member: ${name}`;
                    });
                }
                const membersList = document.getElementById("membersList");
                members.filter(member => member.status.approved).forEach(member => {
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    li.innerHTML = member.addressOfMember + " - " + member.name;
                    membersList.appendChild(li);
                });
                const unapprovedMembersList = document.getElementById("unapprovedMembersList");
                members.filter(member => !member.status.approved).forEach(member => {
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    li.innerHTML = member.addressOfMember + " - " + member.name;
                    // add approve button
                    const approveButton = document.createElement("button");
                    approveButton.classList.add('button', 'is-small', 'is-link');
                    approveButton.innerHTML = "Approve";
                    approveButton.addEventListener("click", async () => {
                        const approve = await contract.voteToAddMember(member.addressOfMember);
                        console.log("approve: ", approve);
                    });
                    li.appendChild(approveButton);
                    unapprovedMembersList.appendChild(li);
                });
                if (unapprovedMembersList.innerHTML == "") {
                    unapprovedMembersList.innerHTML = "No unapproved members";
                }

                // CREATE EVENT LIST
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
                // open events
                for (const daoEventNum in events.filter(event => event.stillOpen)) {
                    const daoEvent = events[daoEventNum];
                    console.log("daoEvent: ", daoEvent);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let title = document.createElement('strong');
                    title.innerHTML = daoEvent.title;
                    li.appendChild(title);

                    let description = document.createElement('span');
                    description.classList.add('content');
                    description.innerHTML = ":    " + daoEvent.description;
                    li.appendChild(description);

                    let attendeesString = "     Attendees: ";
                    for (const memberNum in daoEvent.members) {
                        const member = daoEvent.members[memberNum];
                        console.log("member: ", member)
                        attendeesString = attendeesString + member.name + ", ";
                    }
                    console.log("attendeesString: ", attendeesString);
                    attendeesString = attendeesString.slice(0, -2);
                    console.log("attendeesString: ", attendeesString);
                    let attendees = document.createElement("span");
                    attendees.innerHTML = attendeesString
                    li.appendChild(attendees);

                    let joinEventButton = document.createElement("button");
                    joinEventButton.classList.add('button', 'is-small', 'is-link');
                    joinEventButton.innerHTML = "Join Event";
                    joinEventButton.addEventListener("click", async () => {
                        const joinEvent = await contract.joinEvent(daoEvent.id);
                        console.log("joinEvent: ", joinEvent);
                    });
                    li.appendChild(joinEventButton);

                    eventsList.appendChild(li);
                }
                // closed events
                const closedEventList = document.getElementById("closedEventList");
                for (const daoEventNum in events.filter(event => !event.stillOpen)) {
                    const daoEvent = events[daoEventNum];
                    console.log("daoEvent: ", daoEvent);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let title = document.createElement('strong');
                    title.innerHTML = daoEvent.title;
                    li.appendChild(title);

                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = daoEvent.description;
                    li.appendChild(description);

                    // number of attendees
                    let attendeesLabel = document.createElement('p');
                    attendeesLabel.classList.add('content');
                    attendeesLabel.innerHTML = "Number of attendees: ";
                    li.appendChild(attendeesLabel);

                    let attendees = document.createElement("span");
                    attendees.innerHTML = daoEvent.members.length;
                    li.appendChild(attendees);


                    closedEventList.appendChild(li);
                }
                if (closedEventList.innerHTML == "") {
                    closedEventList.innerHTML = "No unapproved events";
                }

                // CREATE CHANGE LIST
                const createChangeForm = document.getElementById("createChangeForm");
                createChangeForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const changeDescription = document.getElementById("createChangeDescription").value;
                    const newChange = await contract.proposeChange(changeDescription);
                    console.log("newChange: ", newChange);
                });

                const changesList = document.getElementById("changeList");
                const changes = await contract.viewAllChanges();
                console.log("changes: ", changes);
                // open changes
                for (const daoChangeNum in changes.filter(change => !change.status.approved)) {
                    const daoChange = changes[daoChangeNum];
                    console.log("daoChange: ", daoChange);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = daoChange.description;
                    li.appendChild(description);

                    let approveChangeButton = document.createElement("button");
                    approveChangeButton.classList.add('button', 'is-small', 'is-link');
                    approveChangeButton.innerHTML = "Approve Change";
                    approveChangeButton.addEventListener("click", async () => {
                        const approveChange = await contract.voteOnChange(daoChange.id);
                        console.log("approveChange: ", approveChange);
                    });
                    li.appendChild(approveChangeButton);

                    changesList.appendChild(li);
                }
                // closed changes
                const approvedChangesList = document.getElementById("approvedChangeList");
                for (const daoChangeNum in changes.filter(change => change.status.approved)) {
                    const daoChange = changes[daoChangeNum];
                    console.log("daoChange: ", daoChange);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = daoChange.description;
                    li.appendChild(description);

                    approvedChangesList.appendChild(li);
                }
                if (approvedChangesList.innerHTML == "") {
                    approvedChangesList.innerHTML = "No approved changes";
                }


                // CREATE PAYMENT LIST
                const createPaymentForm = document.getElementById("createPayment");
                createPaymentForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const recipient = document.getElementById("createPaymentRecipient").value;
                    const amount = document.getElementById("createPaymentAmount").value;
                    const description = document.getElementById("createPaymentDescription").value;
                    const newPayment = await contract.proposePayment(recipient, amount, description);
                    console.log("newPayment: ", newPayment);
                }
                );

                const paymentsList = document.getElementById("paymentList");
                const payments = await contract.viewAllClubPayments();
                console.log("payments: ", payments);
                // open payments
                for (const daoPaymentNum in payments.filter(payment => !payment.status.approved)) {
                    const daoPayment = payments[daoPaymentNum];
                    console.log("daoPayment: ", daoPayment);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = daoPayment.description;
                    li.appendChild(description);

                    let approvePaymentButton = document.createElement("button");
                    approvePaymentButton.classList.add('button', 'is-small', 'is-link');
                    approvePaymentButton.innerHTML = "Approve Payment";
                    approvePaymentButton.addEventListener("click", async () => {
                        const approvePayment = await contract.votePayment(daoPayment.id);
                        console.log("approvePayment: ", approvePayment);
                    });
                    li.appendChild(approvePaymentButton);

                    paymentsList.appendChild(li);
                }
                // closed payments
                const approvedPaymentsList = document.getElementById("approvedPaymentList");
                for (const daoPaymentNum in payments.filter(payment => payment.status.approved)) {
                    const daoPayment = payments[daoPaymentNum];
                    console.log("daoPayment: ", daoPayment);
                    const li = document.createElement("li");
                    li.classList.add("list-item");

                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = daoPayment.description;
                    li.appendChild(description);

                    approvedPaymentsList.appendChild(li);
                }
                if (approvedPaymentsList.innerHTML == "") {
                    approvedPaymentsList.innerHTML = "No approved payments";
                }

                // PRESIDENT VOTING SECTION
                const startElectionForm = document.getElementById("startElection");
                if (await contract.isElectionVotingOpen()) {
                    // hide
                    startElectionForm.style.display = "none";
                }
                startElectionForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const startElection = await contract.voteStartElection();
                    console.log("startElection: ", startElection);
                }
                );

                // vote got president
                const presidentVoteForm = document.getElementById("presidentVote");
                if (!await contract.isElectionVotingOpen()) {
                    // hide
                    presidentVoteForm.style.display = "none";
                }
                presidentVoteForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const presidentVote = await contract.voteForPresident(presidentVoteForm.candidate.value);
                    console.log("presidentVote: ", presidentVote);
                }
                );

                // finalize election
                const finalizeElectionForm = document.getElementById("finalizeElection");
                if (!await contract.isElectionVotingOpen()) {
                    // hide
                    finalizeElectionForm.style.display = "none";
                }
                finalizeElectionForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const finalizeElection = await contract.finalizeElection();
                    console.log("finalizeElection: ", finalizeElection);
                });




            } catch (error) {
                console.error(error);
            }
        });
    } else {
        console.log("No Ethereum browser extension detected, install MetaMask on desktop or visit from a dApp browser on mobile.");
    }
});