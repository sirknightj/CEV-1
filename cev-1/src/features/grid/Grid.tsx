import { BuildingType } from '../../common/helpers';
import Building from '../building/Building';
import './Grid.css';

function Cell() {
	return <div className="Cell"></div>;
}

function Grid({ size, buildings }: { size: number; buildings: BuildingType[] }) {
	return (
		<div className="Grid">
			<div className="grid-cells">
				{Array(size * size)
					.fill(null)
					.map((_, i) => (
						<Cell key={i}></Cell>
					))}
			</div>
			<div className="buildings">
				{buildings.map((type, i) => (
					<Building buildingType={type} key={i} />
				))}
			</div>
		</div>
	);
}

export default Grid;
