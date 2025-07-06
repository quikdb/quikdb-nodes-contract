/**
 * Events service implementation for gRPC
 */

import { ServerWritableStream } from '@grpc/grpc-js';
import { contractManager } from '../contracts';
import { logger } from '../utils/logger';
import * as pb from '../generated/events_pb';

export class EventsServiceImpl {
  
  /**
   * Stream blockchain events
   */
  async streamEvents(call: ServerWritableStream<pb.StreamEventsRequest, pb.StreamEventsResponse>): Promise<void> {
    try {
      const request = call.request;
      const filter = request.getFilter();
      const includeHistorical = request.getIncludeHistorical();

      logger.info('Starting event stream', {
        contractAddresses: filter?.getContractAddressesList(),
        eventNames: filter?.getEventNamesList(),
        fromBlock: filter?.getFromBlock(),
        toBlock: filter?.getToBlock(),
        includeHistorical
      });

      const provider = contractManager.getProvider();
      if (!provider) {
        call.destroy(new Error('No blockchain provider available'));
        return;
      }

      const contracts = contractManager.getContracts();
      if (!contracts) {
        call.destroy(new Error('No contracts available'));
        return;
      }

      // Get contract addresses to monitor
      const contractAddresses = filter?.getContractAddressesList() || [];
      
      // If no specific contracts provided, monitor all known contracts
      const contractsToMonitor: string[] = contractAddresses.length > 0 
        ? contractAddresses 
        : [
            typeof contracts.userLogic?.address === 'string' ? contracts.userLogic.address : '',
            typeof contracts.userStorage?.address === 'string' ? contracts.userStorage.address : '',
            typeof contracts.nodeLogic?.address === 'string' ? contracts.nodeLogic.address : '',
            typeof contracts.nodeStorage?.address === 'string' ? contracts.nodeStorage.address : '',
            typeof contracts.resourceLogic?.address === 'string' ? contracts.resourceLogic.address : '',
            typeof contracts.resourceStorage?.address === 'string' ? contracts.resourceStorage.address : ''
          ].filter((addr) => addr !== '');

      // Handle historical events if requested
      if (includeHistorical) {
        const fromBlock = filter?.getFromBlock() || 0;
        const toBlock = filter?.getToBlock() || await provider.getBlockNumber();

        logger.info(`Fetching historical events from block ${fromBlock} to ${toBlock}`);

        try {
          // Get historical logs
          const logs = await provider.getLogs({
            fromBlock,
            toBlock,
            address: contractsToMonitor.length > 0 ? contractsToMonitor : undefined
          });

          for (const log of logs) {
            if (call.cancelled || call.destroyed) {
              break;
            }

            const contractEvent = new pb.ContractEvent();
            contractEvent.setContractAddress(log.address);
            contractEvent.setEventName('Unknown'); // Would need ABI to decode
            contractEvent.setBlockNumber(log.blockNumber);
            contractEvent.setTransactionHash(log.transactionHash);
            contractEvent.setLogIndex(log.index || 0);
            contractEvent.setTimestamp(Date.now()); // Would need to get block timestamp

            // Convert log data to key-value pairs (simplified)
            const argsMap = contractEvent.getArgsMap();
            log.topics.forEach((topic, index) => {
              argsMap.set(`topic${index}`, topic);
            });
            if (log.data) {
              argsMap.set('data', log.data);
            }

            const response = new pb.StreamEventsResponse();
            response.setEvent(contractEvent);

            call.write(response);
          }
        } catch (error) {
          logger.error('Failed to fetch historical events:', error);
        }
      }

      // Setup real-time event listening (simplified approach)
      let eventListener: (() => void) | null = null;

      try {
        const handleLog = async (log: any) => {
          if (call.cancelled || call.destroyed) {
            return;
          }

          try {
            // Filter for our monitored contracts
            if (contractsToMonitor.length > 0 && !contractsToMonitor.includes(log.address)) {
              return;
            }

            const contractEvent = new pb.ContractEvent();
            contractEvent.setContractAddress(log.address);
            contractEvent.setEventName('Unknown'); // Would need ABI to decode
            contractEvent.setBlockNumber(log.blockNumber);
            contractEvent.setTransactionHash(log.transactionHash);
            contractEvent.setLogIndex(log.index || 0);
            contractEvent.setTimestamp(Date.now());

            // Convert log data to key-value pairs (simplified)
            const argsMap = contractEvent.getArgsMap();
            if (log.topics) {
              log.topics.forEach((topic: string, index: number) => {
                argsMap.set(`topic${index}`, topic);
              });
            }
            if (log.data) {
              argsMap.set('data', log.data);
            }

            const response = new pb.StreamEventsResponse();
            response.setEvent(contractEvent);

            call.write(response);
          } catch (error) {
            logger.error('Failed to process event:', error);
          }
        };

        // Listen for new blocks and get their logs
        const blockListener = async (blockNumber: number) => {
          if (call.cancelled || call.destroyed) {
            return;
          }

          try {
            const logs = await provider.getLogs({
              fromBlock: blockNumber,
              toBlock: blockNumber,
              address: contractsToMonitor.length > 0 ? contractsToMonitor : undefined
            });

            for (const log of logs) {
              await handleLog(log);
            }
          } catch (error) {
            logger.error('Failed to get logs for block:', error);
          }
        };

        provider.on('block', blockListener);
        
        eventListener = () => {
          provider.off('block', blockListener);
        };

      } catch (error) {
        logger.warn('Failed to setup real-time event listener:', error);
      }

      logger.info(`Event stream started, monitoring ${contractsToMonitor.length} contracts`);

      // Handle client disconnect
      call.on('cancelled', () => {
        logger.info('Event stream cancelled by client');
        if (eventListener) {
          eventListener();
        }
      });

      call.on('close', () => {
        logger.info('Event stream closed');
        if (eventListener) {
          eventListener();
        }
      });

    } catch (error: any) {
      logger.error('Failed to start event stream:', error);
      call.destroy(new Error(`Failed to start event stream: ${error.message}`));
    }
  }
}

export const eventsService = new EventsServiceImpl();
