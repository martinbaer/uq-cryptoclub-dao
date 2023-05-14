// const CONTRACT_ADDRESS_OLD = "0x4E1ef339d37B5AAeA715412d8CEDfE72291E5f09";
const CONTRACT_ADDRESS = "0x6DAEB0B2a61e78acC56867DE6eBb2099108a5dc9";

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
                presidentDiv.classList.add("title", "is-6");
                presidentDiv.innerHTML = `Current President: ${president.name} - ${president.addressOfMember}`;
                
                // CREATE MEMBER LIST
                const members = await contract.viewAllMembers();
                console.log("members: ", members);
                let currentClubMember = await contract.addressToClubMember(account);
                if (currentClubMember.status.initialized) {
                    // reveal connected screen
                    const connectedScreen = document.getElementById("connectedScreen");
                    connectedScreen.style.display = "block";
                    const myNameDiv = document.getElementById("myName");
                    // add class="subtitle" to myNameDDiv
                    const myName = currentClubMember.name;
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
                for (let daoEvent of events.filter(event => event.stillOpen)) {
                    console.log("daoEvent: ", daoEvent);
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let title = document.createElement('strong');
                    title.innerHTML = "id: " + daoEvent.id + " -> " + daoEvent.title + "  ";
                    li.appendChild(title);
                    
                    let description = document.createElement('span');
                    description.classList.add('content');
                    description.innerHTML = "    " + daoEvent.description;
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
                    joinEventButton.classList.add('button', 'is-small', 'is-info', 'mx-2');
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
                for (let daoEvent of events.filter(event => !event.stillOpen)) {
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let title = document.createElement('strong');
                    title.innerHTML = "id: " + daoEvent.id + " -> " + daoEvent.title;
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
                
                const closeEventForm = document.getElementById("closeEvent");
                closeEventForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const eventId = document.getElementById("closeEventInput").value;
                    await contract.closeEvent(eventId);
                });
                
                
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
                let totalVotes = await contract.totalVotes();
                let neededVotes = Math.floor(totalVotes / 2) + 1;
                for (const daoChange of changes.filter(change => !change.status.approved)) {
                    console.log("daoChange: ", daoChange);
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let description = document.createElement('p');
                    description.classList.add('content', 'mb-2', 'mt-3');
                    description.innerHTML = `id: ${daoChange.id} -> ${daoChange.description} (${daoChange.status.votes}/${neededVotes} votes) `;
                    li.appendChild(description);
                    
                    let progressBar = document.createElement('progress');
                    progressBar.classList.add('progress', 'is-primary');
                    progressBar.value = daoChange.status.votes;
                    progressBar.max = neededVotes;
                    li.appendChild(progressBar);
                    // <progress class="progress is-primary" value="15" max="100">15%</progress>


                    let approveChangeButton = document.createElement("button");
                    approveChangeButton.classList.add('button', 'is-small', 'is-link', 'mt-0', 'mb-3');
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
                for (const daoChange of changes.filter(change => change.status.approved)) {
                    console.log("daoChange: ", daoChange);
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = `id: ${daoChange.id} -> ${daoChange.description}`;
                    li.appendChild(description);

                    li.innerHTML += `<progress class="progress is-success" value="1" max="1"></progress>`;

                    
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
                
                totalVotes = await contract.totalVotes();
                neededVotes = Math.floor(totalVotes / 2) + 1;
                for (const daoPayment of payments.filter(payment => !payment.status.approved)) {
                    console.log("daoPayment: ", daoPayment);
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let description = document.createElement('p');
                    description.classList.add('content', 'mb-1');
                    description.innerHTML = `id: ${daoPayment.id} -> recipient: ${daoPayment.recipient}, amount: ${daoPayment.amount/(Math.pow(10,18))}eth - ${daoPayment.description} (${daoPayment.status.votes}/${neededVotes} votes)`;
                    li.appendChild(description);
                    
                    let progressBar = document.createElement('progress');
                    progressBar.classList.add('progress', 'is-primary');
                    progressBar.value = daoPayment.status.votes;
                    progressBar.max = neededVotes;
                    li.appendChild(progressBar);
                    // <progress class="progress is-primary" value="15" max="100">15%</progress>

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
                for (const daoPayment of payments.filter(payment => payment.status.approved)) {
                    console.log("daoPayment: ", daoPayment);
                    const li = document.createElement("li");
                    li.classList.add("list-item");
                    
                    let description = document.createElement('p');
                    description.classList.add('content');
                    description.innerHTML = `id: ${daoPayment.id} -> recipient: ${daoPayment.recipient}, amount: ${daoPayment.amount/(Math.pow(10,18))}eth - ${daoPayment.description}`;
                    li.appendChild(description);
                    li.innerHTML += `<progress class="progress is-success" value="1" max="1"></progress>`;
                    
                    approvedPaymentsList.appendChild(li);
                }
                if (approvedPaymentsList.innerHTML == "") {
                    approvedPaymentsList.innerHTML = "No approved payments";
                }
                
                // PRESIDENT VOTING SECTION
                const startElectionForm = document.getElementById("startElection");
                // totalVotes = await contract.totalVotes();
                // let election = await contract.viewCurrentElection();
                // neededVotes = Math.floor(totalVotes / 2) + 1;
                // startElectionLabel.innerHTML += `${election.status.votes}/${neededVotes} votes)`; // TODO
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
                
                // vote for president
                const presidentVoteForm = document.getElementById("presidentVote");
                if (!await contract.isElectionVotingOpen()) {
                    // hide
                    presidentVoteForm.style.display = "none";
                }
                const presidentVoteAddress = document.getElementById("presidentVoteAddress");
                presidentVoteForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const presidentVote = await contract.voteForPresident(presidentVoteAddress.value);
                    console.log("presidentVote: ", presidentVote);
                }
                );
                
                // finalize election
                const finalizeElectionForm = document.getElementById("finalizeElection");
                finalizeElectionForm.style.display = "none"; // todo
                if (await contract.isElectionWaitingToBeFinalized()) { // todo
                    // show
                    finalizeElectionForm.style.display = "block";
                }
                finalizeElectionForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const finalizeElection = await contract.finalizeElection();
                    console.log("finalizeElection: ", finalizeElection);
                });
                
                // view all election
                const viewAllElectionsForm = document.getElementById("viewAllElections");
                const viewAllElectionsDiv = document.getElementById("viewAllElectionsDiv");
                viewAllElectionsForm.style.display = "block"; 
                viewAllElectionsForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const pastElections = await contract.viewAllElections();
                    console.log("pastElections: ", pastElections);
                    let i = 0;
                    viewAllElectionsDiv.classList.add("content", "box", "mt-2", "pt-3");
                    let list = document.createElement('ul');
                    viewAllElectionsDiv.innerHTML = "";
                    viewAllElectionsDiv.appendChild(list);
                    
                    pastElections.forEach(async election => {
                        const li = document.createElement("li");
                        li.classList.add("list-item");
                        
                        let description = document.createElement('p');
                        description.classList.add('content');
                        let member = await contract.addressToClubMember(election.winner);
                        description.innerHTML = `Election ${i} winner: ${member.name}`;
                        li.appendChild(description);
                        
                        list.appendChild(li);
                
                        i++;
                    });
                });
                
                
                // voting decay
                const votingDecayForm = document.getElementById("votingDecay");
                const votingDecayButton = document.getElementById("votingDecayButton");
                votingDecayButton.disabled = true;
                if (await contract.checkIfReadyToDecay()) {
                    // show
                    votingDecayButton.disabled = false;
                }
                votingDecayForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const decayVotes = await contract.triggerVotesDecay();
                    console.log("voting decay: ", decayVotes);
                });



                // more info
                const userLookupForm = document.getElementById("userLookup");
                const userLookupField = document.getElementById("userLookupAddress");
                const userLookupButton = document.getElementById("userLookupButton");
                userLookupForm.addEventListener("submit", async (event) => {
                    event.preventDefault();
                    const clubMember = await contract.addressToClubMember(userLookupField.value);
                    console.log("ClubMember: ", clubMember);
                    const userLookupDiv = document.getElementById("clubMemberInfo");
                    userLookupDiv.innerHTML = `Member ID: ${clubMember.id}\n`;
                    userLookupDiv.innerHTML += `<p>Member Address: ${clubMember.addressOfMember}\n<\p>`;
                    userLookupDiv.innerHTML += `<p>Member Name: ${clubMember.name}\n<\p>`;
                    userLookupDiv.innerHTML += `<p>Member Votes: ${clubMember.votes}\n<\p>`;
                    userLookupDiv.innerHTML += `<p>Member Approved: ${clubMember.status.approved}\n<\p>`;
                    
                });
                
                
                
                
            } catch (error) {
                console.error(error);
            }
        });
    } else {
        console.log("No Ethereum browser extension detected, install MetaMask on desktop or visit from a dApp browser on mobile.");
    }
});