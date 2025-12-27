// Demonstration of different complexity levels for the GA framework

use "core"
use "_framework"

actor Main
  new create(env: Env) =>
    let args = env.args
    
    if args.size() < 2 then
      _usage(env)
      return
    end
    
    try
      match args(1)?
      | "simple" => _simple_train(env)
      | "vm" => _vm_train(env)
      | "full" => _full_train(env)
      else
        _usage(env)
      end
    else
      _usage(env)
    end
  
  fun _usage(env: Env) =>
    env.out.print("Usage - Choose your complexity level:")
    env.out.print("  simple_main simple  - Simplest (generic byte mutations)")
    env.out.print("  simple_main vm      - VM-aware (respects nucleos)")
    env.out.print("  simple_main full    - Full-featured (maximum control)")
  
  fun _simple_train(env: Env) =>
    env.out.print("=== SIMPLE: Just 3 methods, framework does everything ===")
    
    // This is all you need! ~50 lines of code total.
    SimpleGA.evolve[PowersOfTwo val, PowersConfig val](env, PowersOfTwo, PowersConfig, "simple_bin/")
    
    env.out.print("Done! Check simple_bin/ for results.")
  
  fun _vm_train(env: Env) =>
    env.out.print("=== VM-AWARE: Respects nucleos but still simple ===")
    
    // VM-aware evolution with nucleo-respecting mutations
    VMGA.evolve[VMPowersOfTwo val](env, VMPowersOfTwo, 150, 1500, "vm_bin/")
    
    env.out.print("Done! Check vm_bin/ for results.")
  
  fun _full_train(env: Env) =>
    env.out.print("=== FULL: Maximum control and customization ===")
    
    // Use the full framework for complete control
    let reporter = GenericReporter(env, "full_bin/")
    GenericGAController[PowersDomain val, PowersGenomeOperations val, PowersEvolutionConfig val]
      .create(env, PowersDomain, PowersGenomeOperations, PowersEvolutionConfig, reporter)
    
    env.out.print("Full evolution started. Check full_bin/ for detailed results.")