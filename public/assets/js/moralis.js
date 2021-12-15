const serverUrl = "https://z1eyoosorc33.usemoralis.com:2053/server";
const appId = "L563XKPqHK0pCsrWBAP0xVdAVVFS5fuFteMhprgk";
const nftContractAddress = '0xaaeb64f6366776dc6b89e09b512d00872bec65ad';

Moralis.start({
  serverUrl,
  appId,
});

function fetchNFTMetadata(NFTs) {
	let promises = [];
	for (let i =0; i < NFTs.result.length; i++) {
		let nft = NFTs.result[i];
		let id = nft.token_id;
		let token_uri =  nft.token_uri;
		promises.push(
			fetch(token_uri)
			.then(res => res.json())
			.then(res => {nft.metadata = res;})
			.then(res => {return nft;})
		);
	}
	return Promise.all(promises);
}

function renderNFT(NFTs) {
	const parent = document.getElementById("nftListing")
	console.log(NFTs);
	parent.innerHTML = "";
	for (let i =0; i< NFTs.length; i++) {
		const nft = NFTs[i];
		let htmlString = `
		<div class="card">
		<img class="card-img-top" src="${nft.metadata.external_url}" alt="">
		<div class="card-body">
			<h5 class="card-title">${nft.metadata.name}</h5>
			<p class="card-text">${nft.metadata.description}</p>
		</div>
		</div>
		`
		let col = document.createElement("div");
		col.className = "col col-md-3"
		col.innerHTML = htmlString;
		parent.appendChild(col);
	}
}

function showNFTs() {
	let NFTMetadata = [
		{
			"metadata": {
  "image": "https://ipfs.io/ipfs/bafybeiap6ldu7bbyviuthmniv7hkvb4vus7ijuhzm2ov2u25akarov6ziu/wikipedia/wK.png",
  "description": "Wikpedia Chess Piece Image of White King",
  "name": "Wikipedia King White",
  "external_url": "https://ayadhan.herokuapp.com/assets/img/chesspieces/wikipedia/wK.png"
	}
		},
		{"metadata": {
			  "image": "https://ipfs.io/ipfs/bafybeiap6ldu7bbyviuthmniv7hkvb4vus7ijuhzm2ov2u25akarov6ziu/wikipedia/wQ.png",
			  "description": "Wikpedia Chess Piece Image of White Queen",
			  "name": "Wikipedia Queen White",
			  "external_url": "https://ayadhan.herokuapp.com/assets/img/chesspieces/wikipedia/wQ.png"
		}}
	];
	renderNFT(NFTMetadata);
}

async function getNFTs() {
	const web3 = await Moralis.enableWeb3();
	let account = (await web3.eth.getAccounts())[0]
	let NFTs = await Moralis.Web3API.account.getNFTsForContract({ chain: 'rinkeby', token_address: nftContractAddress, address: account });
	console.log(NFTs);
	NFTWithMetadata = await fetchNFTMetadata(NFTs);
	console.log(NFTWithMetadata);
	renderNFT(NFTWithMetadata);
}

/** Add from here down */
async function login() {
  let user = Moralis.User.current();
  if (!user) {
    const authOptions = {
      signingMessage: "Hello World!",
      chainId: 4,
    };
    user = await Moralis.authenticate(authOptions)
      .then(function (user) {
        console.log("logged in user:", user);
        console.log(user.get("ethAddress"));
      })
      .catch(function (error) {
        console.log(error);
      });
  }
  getNFTs();
}

async function logOut() {
  await Moralis.User.logOut();
  console.log("logged out");
}

login();