# Initial measured client-timing run

Source commit: 13069f71855047c8783ebbed5fbc4d0ec172da0b.
Hosted validation: https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40623696963
Original artifact ID: 12788188603. Downloaded ZIP SHA-256: 294f3b32b3436237b83a604d04205a21962d2bb33e69e3a14f874ff7d14d3fd2.

The raw JSON and summary are retained as originally measured. This run recorded client elapsed time but did not fully drain the SQL response stream; expected STATISTICS IO messages were missing. Its apparent 91.956% median reduction is a limited synthetic observation, not a production result or toolkit optimization claim. Do not use this run as evidence of logical-read reduction. A later implementation fixes reader draining and asserts IO-message capture. Keep this earlier run to make that correction transparent.
