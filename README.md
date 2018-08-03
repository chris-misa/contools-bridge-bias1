# Bridge Bias 1 Experiment

Measure the bridge bias using dind.

# Notes

Perhaps spinning up containers for each measurment is a little much.
Better for the container to run as a service, allowing exec-ing the actual commands from the host (for now, api for the future).
Then we can add cool-down period after container spins up before taking measurements.
or
We can spin up the entire hierachy, then take measurements from different points.

This might not make much of a difference.
