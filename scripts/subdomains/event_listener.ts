import { mainPackage } from "../config/constants";

let lastCursor: {
    txDigest: string;
    eventSeq: string;
} | null = null;
let hasNextPage: boolean = false;
let isRunning = false;
let lastExecution: number = 0;
const executionDelayTolerance = 30; // we tolerate 30s of delay.

const queryEvents = async (cursor) => {

    const config  = mainPackage.testnet;

    const events = await config.provider.queryEvents({
        query: {
            MoveEventType: 
        },
        order: 'ascending',
        cursor: lastCursor
    });

    console.dir(events, {depth: null});
}


const queryEventsPlanner = async (eventType: string, ) => {
    // get current timestamp. We tolerate a delay of 10S 
    const timestamp = new Date().getTime();

    if(isRunning && (lastExecution && lastExecution + executionDelayTolerance < timestamp)) return;
    // save the timestamp for our last execution
    lastExecution = timestamp;
    isRunning = true;



    // after everything, we set `isRunning` to false so the worker can pick the task up.
    isRunning = false;
}


// while(true){
//     console.log("Event indexer initialized..");
//     setInterval(() => queryEventsPlanner(`${config.subdomainsPackageId}::subdomains::SubDomainTweakEvent`)), 1000);
// }

