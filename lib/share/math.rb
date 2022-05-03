# frozen_string_literal: true

SIDE_LEFT = -1
SIDE_RIGHT = 1

##
# Checks wether a given point is closer to the left or right step of a given interval
#
# @return -1 for left and 1 for right
# @param interval [Integer] interval size.
# @param point [Integer] point to check.
def closest_interval_side(interval, point)
  (point % interval) * 2 < interval ? SIDE_LEFT : SIDE_RIGHT
end
