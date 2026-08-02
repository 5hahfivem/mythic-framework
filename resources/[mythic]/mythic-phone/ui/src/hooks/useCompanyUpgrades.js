import { useSelector } from 'react-redux';

export default () => {
	const JobData = useSelector((state) => state.data.data.JobData);
	return (jobId, upgrade) => {
		const job = (JobData || []).find((j) => Boolean(j) && j.Id === jobId);
		return Boolean(job && job.Upgrades && job.Upgrades[upgrade]);
	};
};
