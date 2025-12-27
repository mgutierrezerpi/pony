# GA Framework Complexity Comparison

The framework now supports three levels of complexity, from beginner-friendly to full-featured research tool.

## 🟢 Level 1: Simple GA (`SimpleGA`) - **~50 lines of code**

**Perfect for**: Beginners, quick prototypes, simple problems

```pony
// Define your problem with just 3 methods!
primitive MyProblem is SimpleProblem
  fun genome_size(): USize => 20                    // How big is a genome?
  fun fitness(genome: Array[U8] val): F64 => 0.8    // How good is this genome?
  fun display(genome: Array[U8] val): String => "Result"  // Show results
  
// Run evolution in one line!
SimpleGA.evolve[MyProblem val, DefaultConfig val](env, MyProblem)
```

**What you get automatically:**
- Random genome generation
- Generic byte-level mutations
- Tournament selection
- Population management
- Progress reporting
- Sensible default parameters

**Trade-offs:**
- ✅ Extremely easy to use
- ✅ Great for learning/prototyping  
- ❌ Generic mutations don't understand your problem structure
- ❌ Limited customization options

---

## 🟡 Level 2: VM-Aware GA (`VMGA`) - **~100 lines of code**

**Perfect for**: VM problems, nucleo/codon respect, moderate customization

```pony
// Define a VM-aware problem
primitive MyVMProblem is VMProblem
  fun nucleos_per_genome(): USize => 16             // How many instructions?
  fun fitness(genome: Array[U8] val): F64 => 0.9    // Test the VM program
  fun display(genome: Array[U8] val): String => "VM results"
  
  // Optional: customize VM structure
  fun max_opcode(): U8 => 11        // 12 opcodes (0-11)
  fun max_register(): U8 => 3       // 4 registers (0-3)
  
// Run VM-aware evolution
VMGA.evolve[MyVMProblem val](env, MyVMProblem, 200, 1000)
```

**What you get:**
- **Nucleo-aware mutations**: Respects instruction boundaries
- **Valid opcode/register generation**: No invalid instructions
- **Codon-preserving crossover**: Maintains functional units
- **Configurable VM parameters**: Opcodes, registers, instruction size
- **Smart heavy mutation**: Can break codons when needed

**Trade-offs:**
- ✅ Respects your VM structure
- ✅ Still very easy to use
- ✅ Better for VM/instruction problems
- ❌ VM-specific (not for other problem types)
- ❌ Some parameters still fixed

---

## 🔴 Level 3: Full Framework - **~400 lines of code**

**Perfect for**: Research, maximum control, complex custom behavior

```pony
// Full control over every aspect
primitive MyDomain is ProblemDomain
  fun genome_size(): USize => 48
  fun random_genome(rng: Rand): Array[U8] val => // Custom genome generation
  fun evaluate(genome: Array[U8] val): F64 => // Custom fitness function
  fun perfect_fitness(): F64 => 0.99
  fun display_result(genome: Array[U8] val): String => // Custom display

primitive MyOps is GenomeOperations  
  fun mutate(rng: Rand, genome: Array[U8] val): Array[U8] val => // Custom mutations
  fun heavy_mutate(rng: Rand, genome: Array[U8] val): Array[U8] val => // Custom heavy mutations
  fun crossover(rng: Rand, a: Array[U8] val, b: Array[U8] val): (Array[U8] val, Array[U8] val) => // Custom crossover

primitive MyConfig is GAConfiguration
  fun population_size(): USize => 200
  fun tournament_size(): USize => 3
  fun mutation_rate(): F64 => 0.15
  // ... all parameters customizable

// Full setup
let reporter = GenericReporter(env, "output/")
GenericGAController[MyDomain val, MyOps val, MyConfig val]
  .create(env, MyDomain, MyOps, MyConfig, reporter)
```

**What you get:**
- **Complete control**: Every parameter, every behavior
- **Custom genetic operations**: Implement any mutation/crossover strategy
- **Advanced reporting**: Custom metrics, logging, persistence
- **Adaptive diversity**: Automatic stagnation detection and response
- **Parallel evaluation**: Multi-threaded fitness evaluation
- **Resume capability**: Save/load evolution state

**Trade-offs:**
- ✅ Maximum flexibility and control
- ✅ Perfect for research and complex problems
- ✅ All framework features available
- ❌ More code to write
- ❌ Steeper learning curve

---

## 📊 Comparison Table

| Feature | Simple GA | VM GA | Full Framework |
|---------|-----------|-------|----------------|
| **Lines of user code** | ~50 | ~100 | ~400 |
| **Setup complexity** | 1 line | 1 line | ~20 lines |
| **Learning curve** | Minutes | 1 hour | Few hours |
| **Customization** | Low | Medium | Complete |
| **Problem-awareness** | Generic | VM/Nucleo | Any |
| **Mutation quality** | Basic | Smart | Custom |
| **Performance** | Good | Better | Best |
| **Research features** | Basic | Some | All |

---

## 🎯 When to Use Which?

### Start with Simple GA if:
- You're new to genetic algorithms
- You want to test an idea quickly  
- Your problem doesn't have special structure
- You need results in 10 minutes

### Move to VM GA if:
- Your genomes represent programs/instructions
- You need nucleo/codon awareness
- Simple GA doesn't respect your structure
- You want better mutation quality

### Use Full Framework if:
- You're doing research
- You need custom genetic operations
- You want maximum performance
- You need advanced features (metrics, resume, etc.)

---

## 🚀 Migration Path

**Start Simple → Grow Complex**

1. **Prototype** with Simple GA to validate your fitness function
2. **Improve** with VM GA if you need structure awareness  
3. **Optimize** with Full Framework when you need maximum control

Each level builds on the previous, so migration is straightforward!

---

## 💡 Example: Powers of Two Evolution

All three levels solve the same problem (evolve VM programs to compute 2^n):

- **Simple**: `SimpleGA.evolve[PowersOfTwo](env, PowersOfTwo)` 
- **VM-Aware**: `VMGA.evolve[VMPowersOfTwo](env, VMPowersOfTwo)`
- **Full**: Complete PowersDomain + PowersGenomeOperations + PowersEvolutionConfig

The simple version might take longer to converge, but it's **much** easier to implement and understand!