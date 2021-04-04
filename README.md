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

Then, on a new terminal, go to the repository's root folder and run this to
deploy your contract:

```sh
npx hardhat run scripts/deploy.js --network localhost
```

Finally, we can clone and run the frontend with:

```sh
git clone https://github.com/Dhanush123/stableratioswap-frontend.git
cd stableratioswap-frontend
npm install
npm start
```