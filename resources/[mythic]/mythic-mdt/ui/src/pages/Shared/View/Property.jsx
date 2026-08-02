import React, { useState, useEffect } from 'react';
import { Alert, Grid, List, ListItem, ListItemText } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { Link } from 'react-router-dom';
import { toast } from 'react-toastify';
import Moment from 'react-moment';
import { useParams } from 'react-router';

import Nui from '../../../util/Nui';
import { Loader } from '../../../components';
import { usePerson } from '../../../hooks';

import { PropertyTypes } from '../../../data';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		padding: '20px 10px 20px 20px',
		height: '100%',
		position: 'relative',
	},
	link: {
		color: theme.palette.text.alt,
		transition: 'color ease-in 0.15s',
		'&:hover': {
			color: theme.palette.primary.main,
		},
	},
}));

export default ({ match }) => {
	const classes = useStyles();
	const formatPerson = usePerson();
	const params = useParams();

	const [loading, setLoading] = useState(false);
	const [err, setErr] = useState(false);
	const [property, setProperty] = useState(null);

	useEffect(() => {
		const fetch = async () => {
			setLoading(true);
			try {
				let res = await (
					await Nui.send('View', {
						type: 'property',
						id: params.id,
					})
				).json();

				if (res) setProperty(res);
				else toast.error('Unable to Load');
			} catch (err) {
				console.log(err);
				toast.error('Unable to Load');
				setErr(true);
			}

			setLoading(false);
		};
		fetch();
	}, []);

	if (loading) return <Loader text="Loading" />;

	return (
		<div className={classes.wrapper}>
			{Boolean(property) && !err ? (
				<Grid container spacing={2}>
					<Grid item xs={6}>
						<List>
							<ListItem>
								<ListItemText primary="Address" secondary={property.label} />
							</ListItem>
							<ListItem>
								<ListItemText
									primary="Type"
									secondary={PropertyTypes[property.type] ?? 'Property'}
								/>
							</ListItem>
							<ListItem>
								<ListItemText
									primary="Owner"
									secondary={
										property.owner ? (
											<Link
												className={classes.link}
												to={`/search/people/${property.owner.SID}`}
											>
												{formatPerson(
													property.owner.First,
													property.owner.Last,
													false,
													property.owner.SID,
												)}
											</Link>
										) : (
											'Dynasty 8'
										)
									}
								/>
							</ListItem>
							<ListItem>
								<ListItemText
									primary="Status"
									secondary={
										property.foreclosed
											? 'Foreclosed'
											: property.sold
											? 'Sold'
											: 'For Sale'
									}
								/>
							</ListItem>
						</List>
					</Grid>
					<Grid item xs={6}>
						<List>
							<ListItem>
								<ListItemText
									primary="Value"
									secondary={`$${(property.price ?? 0).toLocaleString()}`}
								/>
							</ListItem>
							<ListItem>
								<ListItemText
									primary="Date Sold"
									secondary={
										property.soldAt ? (
											<Moment date={property.soldAt} unix format="LL" />
										) : (
											'Never Sold'
										)
									}
								/>
							</ListItem>
							<ListItem>
								<ListItemText
									primary="Key Holders"
									secondary={
										property.keys && property.keys.length > 0
											? property.keys.map((k) => (
													<Link
														key={k.SID}
														className={classes.link}
														to={`/search/people/${k.SID}`}
													>
														{formatPerson(k.First, k.Last, false, k.SID)}
													</Link>
											  ))
											: 'None'
									}
								/>
							</ListItem>
						</List>
					</Grid>
				</Grid>
			) : (
				<Alert variant="filled" severity="error">
					Invalid Property ID
				</Alert>
			)}
		</div>
	);
};
