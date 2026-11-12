use std::env;
use std::fs::File;
use std::io::{self, BufWriter, Read, Seek, SeekFrom, Write};
use std::num::NonZeroUsize;
use std::path::Path;
use std::process::ExitCode;
use std::thread;

type Histogram = [u64; 256];
const BUFFER_SIZE: usize = 64 * 1024;

fn count_range(path: &Path, offset: u64, mut remaining: u64) -> io::Result<Histogram> {
    let mut file = File::open(path)?;
    file.seek(SeekFrom::Start(offset))?;

    let mut counts = [0; 256];
    let mut buffer = [0; BUFFER_SIZE];
    while remaining > 0 {
        let block_size = remaining.min(BUFFER_SIZE as u64) as usize;
        let block = &mut buffer[..block_size];
        file.read_exact(block)?;
        for &byte in block.iter() {
            counts[usize::from(byte)] += 1;
        }
        remaining -= block_size as u64;
    }
    Ok(counts)
}

fn histogram(path: &Path, threads: NonZeroUsize) -> io::Result<Histogram> {
    let metadata = path.metadata()?;
    if !metadata.is_file() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "expected a regular file",
        ));
    }
    let file_size = metadata.len();
    if file_size == 0 {
        return Ok([0; 256]);
    }

    let workers = (threads.get() as u64).min(file_size);
    let base_size = file_size / workers;
    let extra_bytes = file_size % workers;

    thread::scope(|scope| {
        let mut handles = Vec::new();
        let mut offset = 0;
        for worker in 0..workers {
            // Give one extra byte to each of the first `extra_bytes` workers.
            let length = base_size + u64::from(worker < extra_bytes);
            let start = offset;
            let handle = thread::Builder::new()
                .spawn_scoped(scope, move || count_range(path, start, length))?;
            handles.push(handle);
            offset += length;
        }

        let mut total = [0; 256];
        for handle in handles {
            let counts = handle
                .join()
                .map_err(|_| io::Error::other("worker thread panicked"))??;
            for (sum, count) in total.iter_mut().zip(counts) {
                *sum += count;
            }
        }
        Ok(total)
    })
}

fn run() -> io::Result<()> {
    let usage = || {
        io::Error::new(
            io::ErrorKind::InvalidInput,
            "usage: byte-histogram <file> [threads]",
        )
    };
    let mut args = env::args_os().skip(1);
    let path = args.next().ok_or_else(usage)?;
    let threads = match args.next() {
        Some(value) => value
            .to_str()
            .and_then(|value| value.parse::<NonZeroUsize>().ok())
            .ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidInput,
                    "threads must be a positive integer",
                )
            })?,
        None => thread::available_parallelism().unwrap_or(NonZeroUsize::MIN),
    };
    if args.next().is_some() {
        return Err(usage());
    }

    let counts = histogram(Path::new(&path), threads)?;
    let mut output = BufWriter::new(io::stdout().lock());
    for (byte, count) in counts.iter().enumerate() {
        writeln!(output, "{byte:02X}: {count}")?;
    }
    output.flush()
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("Error: {error}");
            ExitCode::FAILURE
        }
    }
}
