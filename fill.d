import std.stdio: writeln;
import core.memory: GC;
import std.typecons: Tuple, tuple;
import std.algorithm.iteration: mean;
import std.algorithm.iteration: sum;
import std.datetime.stopwatch: AutoStart, StopWatch;


/* Benchmarking Function */
auto bench(alias fun, string units = "msecs",
          ulong minN = 10, bool doPrint = false)(ulong n, string msg = "")
{
  auto times = new double[n];
  auto sw = StopWatch(AutoStart.no);
  for(ulong i = 0; i < n; ++i)
  {
    sw.start();
    fun();
    sw.stop();
    times[i] = cast(double)sw.peek.total!units;
    sw.reset();
  }
  double ave = mean(times);
  double sd = 0;

  if(n >= minN)
  {
    for(ulong i = 0; i < n; ++i)
      sd += (times[i] - ave)^^2;
    sd /= (n - 1);
    sd ^^= 0.5;
  }else{
    sd = double.nan;
  }

  static if(doPrint)
    writeln(msg ~ "Mean time("~ units ~ "): ", ave, ", Standard Deviation: ", sd);

  return tuple!("mean", "sd")(ave, sd);
}

/* Fill Functions */
auto fill_for(alias x, ulong n)()
{
  alias T = typeof(x);
  auto arr = new T[n];

  for(ulong i = 0; i < n; ++i)
    arr[i] = x;

  return arr;
}

auto fill_foreach(alias x, ulong n)()
{
  alias T = typeof(x);
  auto arr = new T[n];

  foreach(ref el; arr)
    el = x;

  return arr;
}

auto fill_slice(alias x, ulong n)()
{
  alias T = typeof(x);
  auto arr = new T[n];

  arr[] = x;

  return arr;
}

/**
  Here explicitly uses D's GC.malloc with respective scan
  Note that using GC.BlkAttr.NO_SCAN is faster than malloc.
*/
auto fill_mask(alias x, ulong n, uint mask = GC.BlkAttr.NO_SCAN)()
{
  alias T = typeof(x);
  auto arr = (cast(T*)GC.malloc(T.sizeof*n, mask))[0..n];
  if(arr == null)
    assert(0, "Array Allocation Failed!");
  arr[] = x;
  return arr;
}

void main()
{
  double x = 42;
  const(ulong) size = 100_000; ulong ntrials = 100;
  bench!(fill_slice!(x, size), "usecs", 10, true)(ntrials, "Slice: ");
  bench!(fill_foreach!(x, size), "usecs", 10, true)(ntrials, "Foreach: ");
  bench!(fill_for!(x, size), "usecs", 10, true)(ntrials, "For: ");
  bench!(fill_mask!(x, size, GC.BlkAttr.NO_SCAN), "usecs", 10, true)(ntrials, "Slice & GC.BlkAttr.NO_SCAN: ");
  bench!(fill_mask!(x, size, GC.BlkAttr.NONE), "usecs", 10, true)(ntrials, "Slice & GC.BlkAttr.NONE: ");
  bench!(fill_mask!(x, size, GC.BlkAttr.NO_MOVE), "usecs", 10, true)(ntrials, "Slice & GC.BlkAttr.MOVE: ");
}
