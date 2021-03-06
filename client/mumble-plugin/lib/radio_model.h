/* 
 * This file is part of the FGCom-mumble distribution (https://github.com/hbeni/fgcom-mumble).
 * Copyright (c) 2020 Benedikt Hallinger
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


// A radio model for the FGCom-mumble plugin
//
// This just defines some functions that are used from the plugin.
//

#ifndef FGCOM_RADIOMODEL_H
#define FGCOM_RADIOMODEL_H

/*
 * Calculates the distance to horizon for an given observer at height h.
 *
 * @param h height in meters above surface
 * @returns the distance to horizon in km
 */
double fgcom_radiowave_getDistToHorizon(float h);


/*
 * See if two observers can see each other.
 * 
 * @param dist Distance between the two observers in km
 * @param hA   height of observer A, in meters above surface
 * @param hB   height of observer B, in meters above surface
 * @return height of observer B above A's horizon in meters (if this is negative, its hidden).
 */
double fgcom_radiowave_heightAboveHorizon(double dist, float hA, float hB);


/*
 * Get slant distance (length of line of sight)
 * 
 * @param surfacedist surface distance between the two objects in km
 * @param hah  visible height of observed object above horizon in m (@see heightAboveHorizon()), must be corrected for own height!
 * @return double slant distance in km
 */
double fgcom_radiowave_getSlantDistance(double surfacedist, double hah);


/*
 * Get angle of visible height above horizon.
 * 
 * @param surfacedist surface distance between the two objects in km
 * @param hah  visible height of observed object above horizon in m (@see heightAboveHorizon()), must be corrected for own height!
 * @return float Degrees of the visible height
 */
double fgcom_radiowave_degreeAboveHorizon(double surfacedist, double hah);


/*
 * Get distance (great circle) for two objects based on lat/lon
 * 
 * @param lat1  Latitude of object A
 * @param lon1  Longitude of object A
 * @param lat2  Latitude of object B
 * @param lon2  Longitude of object B
 * @return great circle distance in km (as the crow flies)
 */
double fgcom_radiowave_getSurfaceDistance(double lat1, double lon1, double lat2, double lon2);


/*
 * Get signal strength
 * 
 * @param lat1  Latitude of object A
 * @param lon1  Longitude of object A
 * @param alt1  height of observer A, in meters above surface
 * @param lat2  Latitude of object B
 * @param lon2  Longitude of object B
 * @param alt2  height of observer A, in meters above surface
 * @param power Signal sending power in watts
 * @return float 0.0=no signal; 1.0=best signal
 */
float fgcom_radiowave_getSignalStrength(double lat1, double lon1, float alt1, double lat2, double lon2, float alt2, float power);

#endif
