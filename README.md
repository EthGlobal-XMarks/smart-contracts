## Description
-  The Smart Contract Architecture that powers our game.
### Smart Contracts
* Core Functions:

    - *setPrizesContract*: Links a prize contract address to award winners.
    - *startNewGame*: Initiates a new game instance, requesting random numbers to determine the game's target coordinates.
    - *submitGuess* : Allows players to submit guesses for a game's target location. Limits guesses per player and ensures game activity.
    - *recordWinner* : Marks a game's winner, awards them via the prize contract, and concludes the game.
    addVerifiedWallet: Manages wallet verification, crucial for guess submissions after the initial guess.

* Chainlink Integration:

    - *Randomness* : Utilizes Chainlink VRF (Verifiable Random Function) to generate secure, random numbers for game target coordinates, ensuring fairness.
    - *Post Request using Chainlink functions *: `FullfillRandomWords` - after the random number's are generated we use the above function to make a post request and integrate to our backend systems. 
