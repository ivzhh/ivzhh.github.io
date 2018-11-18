% Optimization Tips
% ivz hh
% Nov 17, 2018

# Problem Definition

## What is Optimization

. . .

## Make the program run **FASTER**

## Von Neumann Architecture

![Von Neumann Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Von_Neumann_Architecture.svg/330px-Von_Neumann_Architecture.svg.png)

## Which Are Fast?

. . .

* Control Unit
* Arithmetic Unit

. . .

---> **CPU** <---

## Which Are Slow?

. . .

* I/O
* Memory

## Goal

. . .

Trade-off

* cost of **hardware**
* cost of **optimization**

## Traditional Optimization

. . .

[Moore's law](https://en.wikipedia.org/wiki/Moore%27s_law) -> Optimize CPU

. . .

* Register allocation
* SSA
* Sea of Nodes
* JIT, AOT

## Suggestions

* Trust compilers
* Use SIMD

## Trust Compilers

* Write code for humans
* Which is also easier for compilers
* **Rely on compiler for type checking**

## Use SIMD

* Single Instruction **Multiple** Data
* Write **Intrinsics**
* Write code for **auto-vectorization**

# [The Free Lunch Is Over](http://www.gotw.ca/publications/concurrency-ddj.htm)

## Three New Problems

. . .

* Memory Hierachy
* Heterogeneous Computing
* I/O and Network

# Memory Hierarchy

## Slower and Slower

* Register 
* L1 
* L2 
* LLC
* RAM
* SSD
* HDD

## Suggestion on Memory

* Avoid Random Access
  * Stack vs Heap
  * Array vs Linked-List
  * SoA vs AoS
* Cache Data

## Suggestion on Heterogeneous Computing, I/O and Networking

- Different **clock**
- Different Memory
- **Different Programming Model**

## Prepare for Asynchronized

- Async/Await
- Future
- ThreadPool
- Fiber/Coroutine
- Call/CC
- What ever features in your favorite languages!!!

## Arrange Tasks During I/O Access **By Design**

Case Study: OpenGL (heterogeneous computing):

* PBO: use DMA and Overlapped I/O
* Context Switch (Task Queue Flushing)
* Preparation on CPU side:
  * Memory Clear
  * File Loading

# Profiling

## **MOST IMPORTANT**

## Tools

* Concurrency Visualizer (Microsoft)
* Visual Studio Profiler (Microsoft)
* VTune (Intel)

## Concurrency Visualizer

* Sequence of Execution
  * Synchronization
  * I/O
  * Execution

## Visual Studio Profiler

* Hotspot

## VTune

* Hotspot
* Memory Pressure
* Instruction Pressure (Instruction Retirement)

# Conclusion

## Use Async When Coding

## Use Profiling







