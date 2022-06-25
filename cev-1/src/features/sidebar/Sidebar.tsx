import Graph from '../graph/Graph';
import NextMonth from './NextMonth';
import SettingsButton from './SettingsButton';
import './Sidebar.css';
import UpgradesButton from './UpgradesButton';

function Sidebar() {
	const month = 10;
	return (
		<div className="Sidebar">
			<span>Month {month}</span>
			<NextMonth />
			<UpgradesButton />
			<SettingsButton />

			<Graph />
		</div>
	);
}

export default Sidebar;
