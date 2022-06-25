import './App.css';
import { BuildingType } from './common/helpers';
import Grid from './features/grid/Grid';
import Sidebar from './features/sidebar/Sidebar';

function App() {
	const buildings: BuildingType[] = [
		BuildingType.CENTER,
		BuildingType.FOOD1,
		BuildingType.WATER1,
		BuildingType.WATER1,
	];

	return (
		<div className="App">
			<Grid size={15} buildings={buildings} />
			<Sidebar />
		</div>
	);
}

export default App;
