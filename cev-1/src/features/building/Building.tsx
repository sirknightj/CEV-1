import { BuildingType } from '../../common/helpers';
import './Building.css';

function Building({ buildingType }: { buildingType: BuildingType }) {
	return (
		<div className={`Building ${buildingType}`}>
			<img src={require(`../../assets/images/${buildingType}.png`)} />
		</div>
	);
}

export default Building;
