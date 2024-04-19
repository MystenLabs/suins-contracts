import { TransactionArgument, TransactionBlock } from "@mysten/sui.js/transactions";

/**
 * A helper to authorize any app in the SuiNS object.
 */
export const authorizeApp = ({
    txb, adminCap, suins, type, suinsPackageIdV1
}: {
    txb: TransactionBlock;
    adminCap: string;
    suins: string;
    type: string;
    suinsPackageIdV1: string;
}) => {
  console.log({adminCap, suins, type, suinsPackageIdV1})
    txb.moveCall({
        target: `${suinsPackageIdV1}::suins::authorize_app`,
        arguments: [
          txb.object(adminCap),
          txb.object(suins),
        ],
        typeArguments: [type],
      });
}

/**
 * A helper to deauthorize any app that has been authorized on the SuiNS object.
 */
export const deauthorizeApp = ({
    txb, adminCap, suins, type, suinsPackageIdV1
}: {
    txb: TransactionBlock;
    adminCap: string;
    suins: string;
    type: string;
    suinsPackageIdV1: string;
}
) => {
    txb.moveCall({
        target: `${suinsPackageIdV1}::suins::deauthorize_app`,
        arguments: [
          txb.object(adminCap),
          txb.object(suins),
        ],
        typeArguments: [type],
      });
}

/**
 * A helper to call `setup` function for many apps that create a "registry" to hold state.
 */
export const setupApp = ({
    txb, adminCap, suins, target, args
}: {
    txb: TransactionBlock;
    adminCap: string;
    suins: string;
    target: `${string}::${string}`,
    args?: TransactionArgument[];
}
) => {
    txb.moveCall({
        target: `${target}::setup`,
        arguments: [
          txb.object(adminCap),
          txb.object(suins),
          ...(args || [])
        ],
      });
}
