const Lottery = artifacts.require('Lottery');
const truffleAssert = require('truffle-assertions');
const timeMachine = require('ganache-time-traveler');

contract('Lottery', async accounts => {
    before( async () => {
        contractInstance = await Lottery.deployed();
        const fee = await contractInstance.getFee();
        assert.equal(fee.toNumber(), 1, 'Fee is not as expected');
        // const endTime = await contractInstance.getEndTime();
        // assert.equal(endTime.toNumber(), Date.now() + 300, 'Uncorrect end time');
    })

    beforeEach(async() => {
        let snapshot = await timeMachine.takeSnapshot();
        snapshotId = snapshot['result'];
    });
 
    afterEach(async() => {
        await timeMachine.revertToSnapshot(snapshotId);
    });

    it('should enter lottery with correct amount', async () => {
        let result = await contractInstance.enterLottery({from: accounts[0], value: 1});
        let participant = await contractInstance.getParticipant(0);
        assert.equal(participant, accounts[0], 'the account didn\'t register as a participant');
        await truffleAssert.fails(
            contractInstance.enterLottery({from: accounts[1], value: 2}),
            truffleAssert.ErrorType.REVERT,
            'Please provide the correct fee to be able to enter the lottery'    
        )
    })

    it('should not enter lottery more than once', async () => {
        await contractInstance.enterLottery({from: accounts[2], value: 1});
        await truffleAssert.fails(
            contractInstance.enterLottery({from: accounts[2], value: 1}),
            truffleAssert.ErrorType.REVERT,
            'Already entered the lottery'    
        )
    })

    it('should not be able to call withdrawal until lottery has ended', async () => {
        await truffleAssert.fails(
            contractInstance.withdrawal({from: accounts[0]}),
            truffleAssert.ErrorType.REVERT,
            'The lottery is still active'
        )
    })

    it('should not let enter lottery when it has ended', async () => {
        // advance to end of lottery
        await timeMachine.advanceTimeAndBlock(350);
        // will fail trying to call the ChainLink's VRF
        await truffleAssert.fails(
            contractInstance.enterLottery({from: accounts[3], value: 1}),
        )
    })

})