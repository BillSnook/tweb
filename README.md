# tweb
Raspberry Pi program to demonstrate interaction with hardware and communication with each other.

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
  thread - repeat
    read user text from console, write to host
    read response data and output to console

listen
  create socket on port to listen on
  thread - repeat
    listen on socket until an incoming connection is detected then
      start serverThread to accept connection and handle incoming data

consume
  thread - repeat
    listen on stdin (with echo off) and handle input

threader
  start thread with runThreads routine
    runThreads routine gets next threadControl structure
    threadControl determines which thread routine to run and runs it
      the selected routine runs on it's own thread, which exits when the routine returns
      
handler
  gets called with input received on server threads and from console input
  if the input represents a known command, that command is executed
  example: blink runs blink subprogram to blink LEDs on device with LEDs attached
  
hardware
  initialize and operate device GPIO pins to support handler subprograms

signals
manage signals environment and handle ^C (the interrupt signal) for a better exit


