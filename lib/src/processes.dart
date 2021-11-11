library rested.processes;

ProcessManager pman = ProcessManager();

class ProcessManager {
    List<Process> processes = [];
    int pidCounter = 0;

    int createProcess(Arguments args) {
        int _pid = pidCounter++;
        processes.insert(_pid, Process(args));
        return _pid;
    }

    Process? getProcess(int pid) {
        return processes[pid];
    }
}

class Process {
    DateTime createdAt;
    RestedRequest request;

    Process(this.request) {
        createdAt = DateTime.now();
    }
}