import Map, { NavigationControl } from 'react-map-gl/maplibre';
import maplibregl from 'maplibre-gl';

import 'maplibre-gl/dist/maplibre-gl.css';

import mapStyle from './mapStyle.json';

const MapView = () => {
  return (
    <Map
      initialViewState={{
        longitude: 0,
        latitude: 51.5,
        zoom: 6,
      }}
      style={{width: '100%', height: '100%'}}
      mapLib={maplibregl}
      mapStyle={mapStyle}
      hash={true}
    >
      <NavigationControl position="top-left" showCompass={false} />
    </Map>
  );
};

export default MapView;
