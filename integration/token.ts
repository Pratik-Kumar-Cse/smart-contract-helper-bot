function contractIntegration(web3: Web3, subscriptionId: number, tierId: number, tokenAddressId: number): void {
  const contractAddress = '0x...'; // address of the RecurringPayments contract
  const contractAbi = []; // ABI not provided
  
  const RecurringPaymentsContract = new web3.eth.Contract(contractAbi, contractAddress);
  
  // Call createNewSubscription function
  RecurringPaymentsContract.methods.createNewSubscription(subscriptionId, tierId, tokenAddressId)
    .send({ from: '0x...', value: '1000000000000000000' })
    .then((receipt: any) => {
      console.log('Transaction receipt: ', receipt);
    })
    .catch((error: any) => {
      console.log('Error creating new subscription: ', error);
    });
  
  // Call cancelSubscription function
  RecurringPaymentsContract.methods.cancelSubscription(subscriptionId, tokenId)
    .send({ from: '0x...' })
    .then((receipt: any) => {
      console.log('Transaction receipt: ', receipt);
    })
    .catch((error: any) => {
      console.log('Error canceling subscription: ', error);
    });
  
  // Call upgradeAndActivatesubscriptionPlan function
  RecurringPaymentsContract.methods.upgradeAndActivatesubscriptionPlan(subscriptionId, tokenId, tierId, tokenAddressId)
    .send({ from: '0x...', value: '1000000000000000000' })
    .then((receipt: any) => {
      console.log('Transaction receipt: ', receipt);
    })
    .catch((error: any) => {
      console.log('Error upgrading subscription plan: ', error);
    });
  
  // Call executeRecurringPayment function
  RecurringPaymentsContract.methods.executeRecurringPayment(subscriptionId, [tokenId1, tokenId2])
    .send({ from: '0x...' })
    .then((receipt: any) => {
      console.log('Transaction receipt: ', receipt);
    })
    .catch((error: any) => {
      console.log('Error executing recurring payment: ', error);
    });
} 

// Require error statement
// If contract ABI is not provided, it is not possible to call the functions and the program will throw an error. It is necessary to obtain the ABI to properly integrate backend and frontend.