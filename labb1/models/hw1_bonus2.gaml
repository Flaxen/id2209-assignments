/**
* Name: hw1_bonus1
* Based on the internal empty template.
* 
* This version should be passed with both bonus
* Author: Flaxen
* Tags: 
*/


model hw1_bonus2

/* Insert your model definition here */

global {
	
	int numberOfPeople <- 30;
	int numberOfStores <- 5;
	int numberOfGuards <- 1;
	
	int numberOfFoodStores <- 0;
	int numberOfDrinkStores <- 0;
	
	
	int numberOfInfoCenters <- 1;
	int distanceThreshold <- 2;
	
	init {
		create Guest number:numberOfPeople;
		create Store number:numberOfStores;
		create InfoCenter number:numberOfInfoCenters;
		create SecurityGuard number:numberOfGuards;
		
		
		loop counter from: 1 to: numberOfPeople {
			Guest my_agent <- Guest[counter-1];
			my_agent <- my_agent.setName(counter -1);
		}
		
		loop counter from: 1 to: numberOfStores {
			Store my_agent <- Store[counter-1];
			my_agent <- my_agent.setName(counter-1);
		}
		
		loop counter from: 1 to: numberOfInfoCenters {
			InfoCenter my_agent <- InfoCenter[counter-1];
			my_agent <- my_agent.setName(counter-1);
		}
		
		
	}
	
	
}
species SecurityGuard skills: [moving] {
	
	point targetLocation <- nil; // not actuall location target but location of anything to move towards ex InfoCenter
	Guest target <- nil;
	
	aspect base {
		rgb agentColor <- rgb("blue");
		
		draw circle(1) color: agentColor;
	}
	
	action call(point pos) {
		targetLocation <- pos;	
	}
	
	reflex idle when: targetLocation = nil and target = nil {
		do wander;
	}
	
	reflex gotoTarget when: targetLocation != nil and target = nil {
		do goto target:targetLocation;
	}
	
	reflex askInfoCenter when: !empty(InfoCenter at_distance distanceThreshold) and target = nil and targetLocation != nil {
		ask InfoCenter[0] {
			
			// pick target and remove target form infoCenter list
			myself.target <- self.badGuests[0];
			remove myself.target from: self.badGuests;
			myself.targetLocation <- nil;
		}
	}
	
	reflex huntTarget when: target != nil {
		do goto target:target;
	}
	
	reflex killTarget when: (Guest at_distance distanceThreshold) contains target {
		ask target {
			do die;
		}
		target <- nil;
		write "target eliminated";
		ask InfoCenter[0] {
			if(length(self.badGuests) > 0) {
				myself.targetLocation <- self.location;
			}
		}
	}
	
}

species Guest skills: [moving] {
	bool isHungry <- false;
	bool isThirsty <- false;
	bool bad <- flip(0.1);
	string guestName <- "Undefined";
	
	int memorizedFoodStores <- 0;
	int memorizedDrinkStores <- 0;
	
	list memory <- list(Store);
	
	point targetPoint <- nil;
	Store targetStore <- nil;
	
	//int counter <- 0;
	
	action setName(int num) {
		guestName <- "Guest " + num;
	}
	
	action pickStoreFromMemory {
		
		loop while:true {
			
			ask memory[rnd(1, length(memory)) - 1] {
				
				if((myself.isHungry and self.hasFood) or (myself.isThirsty and self.hasDrink)) { 
					return self.location;
				}
			}
			//write "wrong in own memory " + counter;
			//counter <- counter + 1;
		}
	}
	
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if(bad) {
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
	
	// goes to info center when hungry or thirsty. 
	// if have correct store in memory and 70% flip we go off memory. 
	// sometimes want new epxerience -> goto infocenter
	reflex gotoInfoCenter when: (isHungry or isThirsty) and targetPoint = nil {
		
		if(isHungry and memorizedFoodStores > 0 or isThirsty and memorizedDrinkStores and flip(0.7)) {
			targetPoint <- pickStoreFromMemory();
		} else {			
			targetPoint <- InfoCenter[0].location;
		}
	}
	
	reflex gotoTargetPoint when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex askInfoCenter when: !empty(InfoCenter at_distance distanceThreshold) and (isHungry or isThirsty) {
		ask InfoCenter at_distance distanceThreshold {
			
			Store temp <- self.returnStore(myself.isHungry, myself.isThirsty, myself.memory, myself.memorizedFoodStores, myself.memorizedDrinkStores, myself.bad, myself);
			
			// check if we knew all stores
			// pick from memory in that case
			if(temp = nil) {
				myself.targetPoint <- myself.pickStoreFromMemory();
				break;
				write "does not get here";
			}
			
			// otherwise add new store to memory and go there
			// increment counter for visited stores
			//add temp to: myself.memory;
		
			
			myself.targetPoint <- temp.location;
			
		}
	}
	
	reflex enterStore when: !empty(Store at_distance distanceThreshold) and (isHungry or isThirsty) {
		ask Store at_distance distanceThreshold {
			if((myself.isHungry and self.hasFood) or (myself.isThirsty and self.hasDrink)) {
				
				if(!(myself.memory contains self)) {
					add self to: myself.memory;
				}
				
				if(myself.isHungry) {
					myself.memorizedFoodStores <- myself.memorizedFoodStores + 1;
				} else {
					myself.memorizedDrinkStores <- myself.memorizedDrinkStores + 1;
				}
				
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
		if(flip(0.5)) {
			hasFood <- true;
			hasDrink <- false;
			numberOfFoodStores <- numberOfFoodStores + 1;
		} else {
			hasFood <- false;
			hasDrink <- true;
			numberOfDrinkStores <- numberOfDrinkStores + 1;
		}
		/*if(flip(0.3)) {
			hasFood <- true;
			hasDrink <- false;
			numberOfFoodStores <- numberOfFoodStores + 1;
		} else if(flip(0.3)) {
			hasFood <- false;
			hasDrink <- true;
			numberOfDrinkStores <- numberOfDrinkStores + 1;
		} else {
			hasFood <- true;
			hasDrink <- true;
			numberOfFoodStores <- numberOfFoodStores + 1;
			numberOfDrinkStores <- numberOfDrinkStores + 1;
		}*/
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
	list badGuests;
	
	//int counter <- 0;

	
	action setName(int num) {
		infoCenterName <- "InfoCenter " + num;
	}
	
	action returnStore(bool isHungry, bool isThirsty, list memory, int memorizedFoodStores, int memorizedDrinkStores, bool bad, Guest currentGuest) {
		
		// bad guest check
		if(bad and !(badGuests contains currentGuest)) {
			add currentGuest to: badGuests;
			ask SecurityGuard[0] {
				do call(myself.location);
			}
		}
		
		
		// check if guest has visited all stores of drink/food type
		// return nil if thats the case
		if(isHungry and memorizedFoodStores >= numberOfFoodStores) {
			return nil;
		} else if(isThirsty and memorizedDrinkStores >= numberOfDrinkStores) {
			return nil;
		}
		
		// otherwise try to recomment stores
		loop counter from: 0 to: length(Store) - 1 {
			ask sort_by(Store, each distance_to location)[counter] {
				//Store[rnd(0, numberOfStores-1)] {
				
				
				//write "has memorized " + self.storeName + "?: " + memory contains self + " new memory is " + memory;
				
				if(!(memory contains self) and ((isHungry and self.hasFood) or (isThirsty and self.hasDrink))) {
					//myself.counter <- 0;
					//write "recommends " + self.storeName;
					return self;
				}
			}
			
			//write "recommendation does not work while in info " + counter;
			//counter <- counter + 1;
		}
		
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
			species SecurityGuard aspect:base;
		}
	}
}


















