# tweb
Raspberry Pi program to interact with hardware and to communicate with, or act as, a network server.

Swift code entirely. Accesses C library via Glibc on Linux and Darwin.C on MacOS.
Uses C interface for sockets/networking and threads. Many Bothans died getting those to compile.

This program is a command line program that has two main functional modes.
It is intended to demonstrate, with code, which is the best way to demonstrate,
  that we can communicate between raspberry pi devices over a wifi network.
It also demonstrates the ability to create threads to handle long-running tasks
  including networking and interfacing with the device hardware.


main
  command line argument parsing and command scheduling

sender
  look up hostname to get ip address of target
  connect to that host address
  repeat
    read data from console, write to host
    write response data to console

listen
  create socket on port to listen on
  repeat
    listen on socket until an incoming connection is detected then
      accept connection and start thread to handle incoming data

threader
  start thread with runThreads routine
    runThreads routine gets next threadControl structure
    threadControl determines which thread routine to run and runs it
      the selected routine runs on it's own thread, which dies when the routine returns
  manage signals environment and handle ^C (the interrupt signal)

handler
  gets called with input received on server threads when in listen mode
  if the input represents a known command, that command is executed
  example: blink runs blink subprogram to blink LEDs on device with LEDs attached
  
hardware
  initialize and operate GPIO pins to support handler subprograms


