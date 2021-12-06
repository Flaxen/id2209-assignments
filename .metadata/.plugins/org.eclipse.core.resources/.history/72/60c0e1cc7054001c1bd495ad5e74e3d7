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
	

//	reflex asd when: time mod 50 = 0 {
//		float sum <- 0.0;
//		loop g over: Guest {
//			sum <- sum + g.util;
//		}
//		write name + ": " + "medelvärde: " + sum/length(Guest);
//	}
	
	
		
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
	
	
	rgb agentColor <- #green;
	
	aspect base {
	
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
		ask toTalkTo {
			util <- self.knowledge*myself.knowledgePref + self.personality*myself.personalityPref + self.alcoholTolerence*myself.alcoholTolerencePref + 
				ruleList[nameToInt(myself.team)][nameToInt(self.team)];
			//write myself.name + ": " + util;
			myself.notAskedForUtilYet <- false;
			
			if(ruleList[nameToInt(myself.team)][nameToInt(self.team)] != 0) {
				myself.targetIsSpecial <- true;
				//write myself.name + ": " + "ew found someone of wrong team";
			}
			
		}
		do actOnUtil;
	}
	
	reflex leaveBar when: inBar and time mod rnd(100,200) = 0 and !busy {
		do leaveBar;
	}
	
	action leaveBar {
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
		switch team {
			match("AIK") {
				// slåss(påverkar alla i baren -)
				write "FIGHT";
				do fight;
			}
			match("DIF") {
				// gå till annan bar direkt
			}
			match("HIF") {
				// ring kompisar
			}
			match("MFF") {
				// går ut och slåss(bara deras glädje -)
			}
			match("IFK") {
				// göra narr av alla i det laget (för alla i baren, andra lag happy+, narr laget happy-)
			}
			
		}
	}
	
	action bad {
		// testa någon annan
		do stopConversation;
		universalHappiness <- universalHappiness - 1;
		
	}
	
	action good {
		// stanna kvar i tid
		universalHappiness <- universalHappiness + 1;
	}
	
	action fight {
		
		startedFight <- time;
		
		busy <- true;
		ask toTalkTo {
			busy <- true;
		}
		
		ask targetBar {
			hasFight <- true;
			loop g over: guestList {
				if(!g.busy) {
					ask g {
						universalHappiness <- universalHappiness - 1;
						do leaveBar;
					}
				}
			}
		}
	}
	
	reflex endFight when: startedFight != 0.0 and time = startedFight+100 {
		startedFight <- 0.0;
		
		busy <- false;
		ask toTalkTo {
			busy <- false;
			do leaveBar;
		}
		
		ask targetBar {
			//agentColor <- #red;
			hasFight <- false;
		}
		
		do leaveBar;
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
