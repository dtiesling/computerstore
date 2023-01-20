import Head from 'next/head'
import Link from "next/link";
import {Button, Card, CardActions, CardContent, Container, Typography} from "@mui/material";

export default function Home() {
  return (
    <>
      <Head>
        <title>THE COMPUTER STORE</title>
        <meta name="description" content="THE COMPUTER STORE"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link rel="icon" href="/favicon.ico"/>
      </Head>

      {/*This page is unnecessary for the test but I wanted to get a feel for how the Next.js Link works.*/}
      <Container>
        <Card sx={{maxWidth: 345}}>
          {/* eslint-disable-next-line react/jsx-no-undef */}
          <CardContent>
            <Typography gutterBottom variant="h5" component="div">
              THE COMPUTER STORE
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Browse and search our modest selection of computers.
            </Typography>
          </CardContent>
          <CardActions>
            <Button size="small"><Link href="computerstore">START SHOPPING</Link></Button>
          </CardActions>
        </Card>
      </Container>
    </>
  )
}
