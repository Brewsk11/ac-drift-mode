# DriftMode

## Scoring elements

> [!CAUTION]
> The following document is under construction.
> The information may be inaccurate and are subject to change.

### Zone

While the car is scoring, its position is continously sampled and averaged.
This makes the system points-capped and disallows going over the maximum.

For each sample the score is a weighted sum of the following factors:

| Factor                 | Weight | Calculation | Note                                                                                                               |
| ---------------------- | ------ | ----------- | ------------------------------------------------------------------------------------------------------------------ |
| $F_\mathrm{Speed}$     | $1/5$  |             | Speed has low weight and steep reward curve. Maxing speed but lacking precision or angle is not skillful, so speed |
| $F_\mathrm{Angle}$     | $2/5$  |             |                                                                                                                    |
| $F_\mathrm{Precision}$ | $2/5$  |             |                                                                                                                    |

**Zones** are scored with the rear of the car.<br/>
**Clips** are scored with the front of the car.
