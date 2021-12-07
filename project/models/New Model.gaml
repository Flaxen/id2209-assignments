/**
* Name: project_ver1
* Based on the internal empty template. 
* Author: Flaxen
* Tags: 
*/


model project_ver1

/* Insert your model definition here */
global {
	
	int universalHappiness <- 0;
	
	int numberOfTeams <- 5;
	list<string> teams <- ["AIK", "DIF", "HIF", "MFF", "IFKG"];
	
	list ruleList <- list_with(numberOfTeams, list_with(numberOfTeams, 0.0));
	
	float lowUtilThreshold <- 0.3;
	
	bool pause_flag <- false;
	
	reflex pause_sim when: pause_flag {
		pause_flag <- false;
		do pause;
	}
			
	int numberOfBars <- 4;
	int numberOfGuests <- 20;
	int numberOfFields <- 2;
	
	int distanceThreshold <- 2;
	
	int numberOfAttributes <- 6;
	
	
	init {
		create Bar number:numberOfBars;
		create Guest number:numberOfGuests;	
		create Field number:numberOfFields;
		
		ruleList[0][length(ruleList)-1] <- -0.1;
		
		int j <- 0;
		loop i from:1 to:length(ruleList)-1 {	
			ruleList[i][j] <- -0.1;
			j <- j+1;	
		}
	}
	
}

species Guest skills: [moving, fipa] {
	
	string team <- teams[rnd(length(teams)-1)];
	
	float knowledge <- rnd(1.0);
	float personality <- rnd(1.0);
	float alcoholTolerence <- rnd(1.0);

	float knowledgePref <- rnd(1.0);
	float personalityPref <- rnd(1.0);
	float alcoholTolerencePref <- rnd(1.0); 
	
	point targetPoint <- nil;
	Bar targetBar <- nil;
	
	bool inBar <- false;
	
	bool notAskedForUtilYet <- true;
	
	Guest toTalkTo <- nil;
	float util <- 0.0;
	bool targetIsSpecial <- false;
	list<Guest> alreadySpokenTo;
	bool busy <- false;
	
	float startedFight <- 0.0;
	
	list<Guest> HIF_friends;
	
	
	rgb agentColor <- #green;
	
	aspect base {
		
		if(agentColor = #lightgreen and targetPoint = targetBar.location) {
			agentColor <- #green;
		} else if(agentColor = #blue and targetPoint != nil) {
			agentColor <- #green;
		} else if(agentColor = #cyan and !inBar) {
			agentColor <- #green;
		}
		
		
		draw circle(1) color: agentColor;
	}
	
	reflex idle when: targetPoint = nil {
		do wander;
	}
	
	reflex targetBar when: targetPoint = nil and flip(0.3) and time mod 20 = 0 and !inBar {
		targetBar <- Bar[rnd(length(Bar)-1)];
		targetPoint <- targetBar.location;	
	}
	
	reflex gotoTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex enterBar when: Bar at_distance distanceThreshold contains targetBar and !inBar {
		ask targetBar {
			do addToGuestList(myself);
		}
		inBar <- true;
	}
	
	reflex getGuestToTalkTo when: toTalkTo = nil and inBar and flip(0.05) {
		Guest temp;
		ask targetBar {
			temp <- self.guestList[rnd(length(guestList)-1)];
			if temp != myself and temp.toTalkTo = nil and !(myself.alreadySpokenTo contains temp) {
				add temp to: myself.alreadySpokenTo;
				add myself to: temp.alreadySpokenTo;
				myself.toTalkTo <- temp;
				temp.toTalkTo <- myself;
			}
		}
	}
	
	reflex talkToGuest when: toTalkTo != nil and notAskedForUtilYet {
		notAskedForUtilYet <- false;
		
		ask toTalkTo {
			util <- self.knowledge*myself.knowledgePref + self.personality*myself.personalityPref + self.alcoholTolerence*myself.alcoholTolerencePref + 
				ruleList[nameToInt(myself.team)][nameToInt(self.team)];
			//write myself.name + ": " + util;
			
			if(ruleList[nameToInt(myself.team)][nameToInt(self.team)] != 0) {
				myself.targetIsSpecial <- true;
				//write myself.name + ": " + "ew found someone of wrong team";
			}
			
		}
		do actOnUtil;
	}
	
	reflex fleeFight when: targetBar != nil and targetBar.hasFight and !busy {
		universalHappiness <- universalHappiness - 1;
		//write "bar asking " + self + " to leave bar";
		do leaveBar;
	}
	
	reflex leaveBar when: inBar and time mod rnd(100,200) = 0 and !busy {
		//write "" + self + " relfex leaving bar";
		do leaveBar;
	}
	
	reflex accept_call when: !empty(requests) {
		message toRespond <- requests[0];
		list content <- toRespond.contents;
		Bar b <- content[1];
		
		do agree(message: toRespond, contents: ["ok omw"]);
		
		if(inBar) {
			do leaveBar;
		}
		targetBar <- b;
		targetPoint <- targetBar.location;
		agentColor <- #orange;
		
		
	}
	
	action leaveBar {
		//write "" + self + " leaving bar";
		ask targetBar {
			remove myself from: guestList;
		}
		alreadySpokenTo <- [];
		targetBar <- nil;
		targetPoint <- nil;
		do stopConversation;
		inBar <- false;
		

	}
	
	
	action actOnUtil {
		//write "" + self + " acting on util";
		switch util {
			match_between[0.0, 0.3] {
				if(targetIsSpecial) {
					//write name + ": " + "do MEGA BAD";
					do megaBad;
				} else {
					//write name + ": " + "bad person wuah";
					do bad;
				}
			}
			match_between[0.3, 3.5] {
				if(targetIsSpecial) {
					//write name + ": " + "dont like his team but he is ok";
				} else {
					//write name + ": " + "good friend";
					do good;
				}			
			}
		}
	}
	
	action megaBad {
		write "mega bad. pausing " + team;
		pause_flag <- true;
		
		switch team {
			match("AIK") {
				// slåss(påverkar alla i baren -)
				write "FIGHT";
				do fight;
			}
			match("DIF") {
				// gå till annan bar direkt
				write "EW leaving bar";
				universalHappiness <- universalHappiness - 1;
				do stopConversation;
				do leaveBar;
				agentColor <- #blue;
			}
			match("HIF") {
				// ring kompisar
				write "calling friends";
				if(!empty(HIF_friends)) {
					do start_conversation (to: HIF_friends, protocol: "fipa-request", performative: "request", contents: ["Need help at: ", targetBar]);
					// öka uni happy med len(hiffriends?) alla kom dit och blev glada. ta - alla andra i baren? dom känner sig hotade?
				} else {
					// big sad no friends
					universalHappiness <- universalHappiness - 1;
				}
				
			}
			match("MFF") {
				// går ut och slåss(bara deras glädje -)
				write "lets take this outside!";
				startedFight <- time;
		
				busy <- true;
				ask toTalkTo {
					busy <- true;
				}
				
				
				agentColor <- #cyan;
				targetPoint <- {abs(50 - targetBar.location.x), abs(50 - targetBar.location.y)};
				ask toTalkTo {
					agentColor <- #cyan;
					targetPoint <- {abs(50 - targetBar.location.x - 50), abs(50 - targetBar.location.y - 50)};
				}
				universalHappiness <- universalHappiness - 2;
				
			}
			match("IFKG") {
				// göra narr av alla i det laget (för alla i baren, andra lag happy+, narr laget happy-)
				write "IFK not implemented yet";
				
			}
			
		}
	}
	
	action bad {
		// testa någon annan
		if(!toTalkTo.busy) {
			do stopConversation;
			universalHappiness <- universalHappiness - 1;
		}

		
	}
	
	action good {
		// stanna kvar i tid
		//TODO: check for both good and bad to make sure both are not mega bad before action is taken. if in bad is not enough. what if we make check before bool is set?
		if(team = "HIF") {
			add toTalkTo to: HIF_friends;
		}
		universalHappiness <- universalHappiness + 1;
	}
	
	action fight {
		//write "" + self + "started fight";
		startedFight <- time;
		
		busy <- true;
		ask toTalkTo {
			busy <- true;
		}
		
		
		ask targetBar {
			hasFight <- true;
		}
	}
	
	reflex endFight when: startedFight != 0.0 and time = startedFight+100 and busy {
		startedFight <- 0.0;
		
		
		ask toTalkTo {
			busy <- false;
			do leaveBar;
		}
		
		if(team = "AIK") {
			ask targetBar {
				hasFight <- false;
			}
		}

		
		do stopConversation;
		do leaveBar;
		busy <- false;
	}
	
	action stopConversation {
		if(toTalkTo != nil){
			ask toTalkTo{
				self.toTalkTo <- nil;	
				self.notAskedForUtilYet <- true;
			}
		}

		toTalkTo <- nil;
		notAskedForUtilYet <- true;
	}
	
	int nameToInt(string nameIn) {
		
		loop counter from: 0 to: length(teams)-1 {
			if(teams[counter] = nameIn) {
				return counter;
			}
			
			
		}
		
		write name + ": " +"name not found";
		return -1;
	}
}

species Bar {
	
	bool hasFight <- false;
	
	list<Guest> guestList <- [];
	
	rgb agentColor <- #brown;
	
	aspect base {
			
		if(hasFight) {
			agentColor <- #red;
		} else {
			agentColor <- #brown;
		} 
			
		draw square(2) color: agentColor;
	}
	
	action addToGuestList(Guest toAdd) {
		add toAdd to: guestList;
	}
	
}

species Field {
	rgb agentColor <- #blue;
	
	aspect base {
	
		draw triangle(2) color: agentColor;
	}
}

experiment my_experiment type:gui {
	output {
		display myDisplay {
			species Field aspect:base;
			species Guest aspect:base;
			species Bar aspect:base;
			
		}
		
		display infoDisplay {
			chart "universal happy" type: series x_range:[time-100, time+100] {
				data "data" value: universalHappiness color: #black;
			}
		}
	}
}
