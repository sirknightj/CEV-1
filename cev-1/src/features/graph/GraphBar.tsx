import { ResourceType } from '../../common/helpers';

function GraphBar({ resource }: { resource: ResourceType }) {
	return <div className={`GraphBar ${resource}`}>{resource}</div>;
}

export default GraphBar;
