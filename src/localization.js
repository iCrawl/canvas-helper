let strings = {};

const localize = (localStrings) => (strings = localStrings);

const _ = (string) => {
	const translation = strings[string];
	return translation || string;
};

export { localize, _ };
