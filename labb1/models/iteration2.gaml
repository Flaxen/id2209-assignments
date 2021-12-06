/**
* Name: iteration2
* Based on the internal empty template. 
* Author: Flaxen
* Tags: 
*/


model iteration2

/* Insert your model definition here */

global {
	
	int numberOfPeople <- 30;
	int numberOfStores <- 5;
	int numberOfInfoCenters <- 1;
	int distanceThreshold <- 2;
	
	init {
		create Guest number:numberOfPeople;
		create Store number:numberOfStores;
		create InfoCenter number:numberOfInfoCenters;
		
		
		loop counter from: 1 to: numberOfPeople {
			Guest my_agent <- Guest[counter-1];
			my_agent <- my_agent.setName(counter);
		}
		
		loop counter from: 1 to: numberOfStores {
			Store my_agent <- Store[counter-1];
			my_agent <- my_agent.setName(counter);
		}
		
		loop counter from: 1 to: numberOfInfoCenters {
			InfoCenter my_agent <- InfoCenter[counter-1];
			my_agent <- my_agent.setName(counter);
		}
		
	}
	
	
}

species Guest skills: [moving] {
	bool isHungry <- false;
	bool isThirsty <- false;
	string guestName <- "Undefined";
	
	point targetPoint <- nil;
	
	action setName(int num) {
		guestName <- "Guest " + num;
	}
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if(isHungry and isThirsty) {
			agentColor <- rgb("red");
			
		} else if(isThirsty) {
			agentColor <- rgb("darkorange");
			
		} else if(isHungry) {
			agentColor <- rgb("purple");	
			
		}
		
		draw circle(1) color: agentColor;
	}
	
	reflex getHungry when: !isHungry and !isThirsty {
		isHungry <- flip(0.01);
	}
	
	reflex getThirsty when: !isThirsty and !isHungry {
		isThirsty <- flip(0.01);
	}
	
	reflex idle when: targetPoint = nil {
		do wander;
	}
	
	reflex gotoInfoCenter when: (isHungry or isThirsty) and targetPoint = nil {
		targetPoint <- InfoCenter[0].location;
	}
	
	reflex gotoTargetPoint when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex askInfoCenter when: !empty(InfoCenter at_distance distanceThreshold) {
		ask InfoCenter at_distance distanceThreshold {
			myself.targetPoint <- self.returnStore(myself.isHungry, myself.isThirsty);
		}
	}
	
	reflex enterStore when: !empty(Store at_distance distanceThreshold) {
		ask Store at_distance distanceThreshold {
			if((myself.isHungry and self.hasFood) or (myself.isThirsty and self.hasDrink)) {
				myself.isHungry <- false;
				myself.isThirsty <- false;
				myself.targetPoint <- nil;
			}
		}
		
	}
}

species Store {
	bool hasFood;
	bool hasDrink;
	string storeName <- "Undefined";
	
	init {
		if(flip(0.3)) {
			hasFood <- true;
			hasDrink <- false;
		} else if(flip(0.3)) {
			hasFood <- false;
			hasDrink <- true;
		} else {
			hasFood <- true;
			hasDrink <- true;
		}
	}
	
	action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect base {
		rgb agentColor <- rgb("lightgray");
		
		if(hasFood and hasDrink) {
			agentColor <- rgb("darkgreen");
		} else if(hasFood) {
			agentColor <- rgb("skyblue");
		} else if(hasDrink) {
			agentColor <- rgb("pink");
		}
		
		draw square(2) color: agentColor;
	}
}

species InfoCenter {
	string infoCenterName <- "Undefined";
	
	action setName(int num) {
		infoCenterName <- "InfoCenter " + num;
	}
	
	action returnStore(bool isHungry, bool isThirsty) {
		
		loop counter from: 1 to: numberOfStores {
			if((isHungry and Store[counter-1].hasFood) or isThirsty and  Store[counter-1].hasDrink) {
				return Store[counter-1].location;
			}
		}
		
		write "error no such store";
		return location;
	}
	
	aspect base {
		rgb agentColor <- rgb("yellow");
		

		draw triangle(3) color: agentColor;
	}
}

experiment my_experiment type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Store aspect:base;
			species InfoCenter aspect:base;
		}
	}
}


















