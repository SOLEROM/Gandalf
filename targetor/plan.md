Build a lightweight remote execution system that allows a locally running Claude CLI (with internet access) to operate on a remote embedded Linux device that has no internet connection but is reachable over a direct network link. The system should provide Claude with the ability to read and modify files on the remote filesystem and execute commands on the remote hardware, while maintaining a persistent and structured communication channel.

Design the system as two components: a remote agent that runs on the embedded target and a local client proxy that runs on the host machine alongside Claude CLI. The remote agent is responsible for executing commands, accessing the filesystem, and returning results. The local client maintains a persistent connection to the agent and translates local requests into structured messages sent to the agent.

Use a structured message protocol for communication. JSON is acceptable for the initial implementation because it is simple, human-readable, and easy to debug, especially on constrained systems. However, the protocol should be designed so it can be replaced later with a more efficient encoding such as MessagePack if performance or bandwidth becomes a concern. Messages should include a unique request identifier, a command name, and a payload. The protocol must support both request-response and streaming message types.

The transport layer should be abstracted from the protocol. For the first version, use SSH with stdin and stdout as the communication channel because it provides authentication, encryption, and works reliably even when the target has no internet access. The agent should run as a long-lived process started over SSH, and the client should keep the connection open to avoid repeated SSH overhead.

Do not use WebSocket in the initial design. WebSocket requires a TCP service exposed on the target and is more suitable when both sides are on a routable network or when browser-based clients are involved. In this scenario, where the target is offline and accessed via SSH, WebSocket adds unnecessary complexity and security considerations. However, design the system so that the transport layer can later support alternatives such as a TCP socket or ZeroMQ if needed.

The agent must support core commands including execution of shell commands, reading files, writing files, listing directories, and returning environment information. Execution should support both buffered and streaming output so long-running processes can return incremental logs. Streaming should be implemented as multiple response messages tied to a single request identifier.

The execution subsystem on the agent should use subprocess with non-blocking IO to stream stdout and stderr back to the client in near real time. The filesystem subsystem should safely handle path access, encoding, and file modes. Error handling must be explicit, returning structured error messages with clear codes and descriptions rather than failing silently or crashing.

On the local side, implement a client tool that connects to the agent via SSH, sends structured requests, and processes responses. The client should expose simple commands such as exec, read, and write, and can later be wrapped or aliased so that Claude CLI naturally uses it for all operations. The client should also manage the persistent connection lifecycle and handle reconnection if needed.

Ensure that the system treats the remote filesystem as the single source of truth. Avoid using SSHFS or local mirroring. All file operations should go through the agent to prevent inconsistencies. The system should be designed so that Claude is instructed to use the client tool for both execution and filesystem access, effectively making the remote machine its working environment.

Keep the initial implementation minimal and dependency-free, targeting Python 3.6 compatibility on the remote side. After the basic system is stable, extend it with optional features such as persistent sessions with maintained working directory and environment, command batching, improved logging, and support for alternative transports like ZeroMQ for lower latency and higher throughput.

Test the system incrementally by validating command execution, file operations, streaming behavior, and robustness under failures such as broken connections or long-running processes. The final result should behave as a remote runtime backend for Claude CLI, similar in concept to remote development environments, but optimized for embedded, offline, and resource-constrained targets.

Treat this document as a guiding baseline plan; you are expected to refine, adjust, and improve the design and implementation decisions where appropriate according to best practices and real-world constraints.

