import { ResourceType } from '../../common/helpers';
import './Graph.css';
import GraphBar from './GraphBar';

function Graph() {
	return (
		<div className="Graph">
			<GraphBar resource={ResourceType.WATER}></GraphBar>
			<GraphBar resource={ResourceType.FOOD}></GraphBar>
			<GraphBar resource={ResourceType.OXYGEN}></GraphBar>
			<GraphBar resource={ResourceType.ENERGY}></GraphBar>
			<GraphBar resource={ResourceType.METAL}></GraphBar>
		</div>
	);
}

export default Graph;
