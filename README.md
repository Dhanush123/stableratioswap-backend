# stableratioswap-backend

Other related repos https://github.com/Dhanush123/stableratioswap-frontend https://github.com/Dhanush123/tusd-ratio-adapter https://github.com/Dhanush123/tusd-ratio-jobspec

Link to the deployed frontend https://dhanush123.github.io/stableratioswap-frontend/

## Quick start

The first things you need to do are cloning this repository and installing its
dependencies:

```sh
git clone https://github.com/Dhanush123/stableratioswap-backend.git
cd stableratioswap-backend
npm install
```

Once installed, let's run Hardhat's testing network:

```sh
npx hardhat node
```

Clone and run the frontend with:

```sh
git clone https://github.com/Dhanush123/stableratioswap-frontend.git
cd stableratioswap-frontend
npm install
npm start
```

Then, on a new terminal, go to the backend repository's root folder and run this to
deploy your contract locally:

```sh
npx hardhat run scripts/deployreal.js --network localhost
```
or
```sh
npx hardhat run scripts/deploymock.js --network localhost
```
If you ever delete the ```/contracts``` folder in the frontend repo, you will need to run both of the above commands.

Assuming you've put your credentials in a .env in the backend repository's root folder, run the following to deploy to Kovan:
```sh
npx hardhat run scripts/deployreal.js --network kovan
```