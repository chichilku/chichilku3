# frozen_string_literal: true

##
# Checks wether a given point is closer to the left or right step of a given interval
#
# @return -1 for left and 1 for right
# @param interval [Integer] interval size.
# @param point [Integer] point to check.
def closest_interval_side(interval, point)
  (point % interval) * 2 < interval ? -1 : 1
end
