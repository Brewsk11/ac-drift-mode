# DriftMode

## Scoring elements

> [!CAUTION]
> The following document is under construction.
> The information may be inaccurate and are subject to change.

### Zone

Zones are scored with the rear of the car.

While the car is scoring, its position is continously sampled and averaged.
This makes the system points-capped and disallows going over the maximum.

For each sample the following factors are captured:

| Factor                 | Note                                                                          |
| ---------------------- | ----------------------------------------------------------------------------- |
| $F_\mathrm{Speed}$     | $[0, 1]$ range based on the course maximum and minimum speed defined.         |
| $F_\mathrm{Angle}$     | $[0, 1]$ range based on the course maximum and minimum angle defined.         |
| $F_\mathrm{Precision}$ | $[0, 1]$ range based on how close the car is to the outside line of the zone. |

And the score final score is calculated as:

$$
F_\mathrm{Speed} \times F_\mathrm{Angle} \times F_\mathrm{Precision}
$$

### Clip

Clips are scored with the front of the car.

Clip is scored just once when crossing it's line.

The score is calculated the same way the zone is, except $F_\mathrm{Precision}$ is defined as the ratio of how close the car is to the clip point.

In general clips are easier to score higher on, because the score is taken once, whereas in zone the precision needs to be maintained throughout the whole zone for the same score.